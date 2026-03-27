set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  nix run .#bootstrap-host -- --admin <name> <main-wiki|replica-wiki> <target-host> [ssh-identity-file]
  nix run .#bootstrap-host -- --admin <name> <main-target-host> <replica-target-host> [ssh-identity-file]

USAGE
}

repo_root="$(pwd)"
if [ ! -f "$repo_root/flake.nix" ]; then
  printf 'Run bootstrap-host from the repo root\n' >&2
  exit 1
fi

admin_users_json='@ADMIN_USERS_JSON@'
deploy_signing_public_key='@DEPLOY_SIGNING_PUBLIC_KEY@'

pinned_nix_install_url='https://releases.nixos.org/nix/nix-2.24.14/install'

bootstrap_admin=""
ssh_identity_file=""
main_target=""
replica_target=""
failures=()

if [ "${1:-}" != "--admin" ] || [ "$#" -lt 4 ]; then
  printf 'Bootstrap requires --admin <name>\n' >&2
  usage
  exit 1
fi

bootstrap_admin="$2"
shift 2

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  usage
  exit 1
fi

case "$1" in
  main-wiki|replica-wiki)
    if [ "$1" = "main-wiki" ]; then
      main_target="$2"
    else
      replica_target="$2"
    fi
    ssh_identity_file="${3:-}"
    ;;
  *)
    main_target="$1"
    replica_target="$2"
    ssh_identity_file="${3:-}"
    ;;
esac

admin_keys() {
  printf '%s' "$admin_users_json" | @JQ@ -r --arg user "$1" '.[$user].openssh.authorizedKeys.keys[]? | "      \"" + . + "\""'
}

admin_exists() {
  printf '%s' "$admin_users_json" | @JQ@ -e --arg user "$1" 'has($user)' >/dev/null
}

if ! admin_exists "$bootstrap_admin"; then
  printf 'Unknown admin user for bootstrap: %s\n' "$bootstrap_admin" >&2
  exit 1
fi

make_host_module() {
  local module_file="$1"
  local admin_name="$2"

  cat > "$module_file" <<MODULE
{ ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    trusted-public-keys = [ "${deploy_signing_public_key}" ];
  };

  services.journald.storage = "persistent";

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      AllowAgentForwarding = false;
      AllowGroups = [ "wheel" ];
      AllowTcpForwarding = false;
      ClientAliveCountMax = 2;
      ClientAliveInterval = 300;
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      LoginGraceTime = 20;
      MaxAuthTries = 3;
      MaxSessions = 4;
      PermitRootLogin = "no";
      PermitTunnel = false;
      PermitUserEnvironment = false;
      StreamLocalBindUnlink = false;
      X11Forwarding = false;
    };
  };

  users.users.${admin_name} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    linger = true;
    openssh.authorizedKeys.keys = [
$(admin_keys "$admin_name")
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.do-agent.enable = false;
}
MODULE
}

run_bootstrap() {
  local host_name="$1"
  local target_host="$2"
  local work_dir
  local module_file
  local remote_target
  local try
  local known_hosts_file
  local ssh_cmd
  local scp_cmd
  local admin_target

  work_dir="$(mktemp -d)"
  module_file="$work_dir/host-bootstrap.nix"
  known_hosts_file="$work_dir/known_hosts"
  remote_target="$target_host:/etc/nixos/host-bootstrap.nix"
  admin_target="${bootstrap_admin}@${target_host#*@}"

  ssh_cmd=(ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$known_hosts_file" -o GlobalKnownHostsFile=/dev/null)
  scp_cmd=(scp -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$known_hosts_file" -o GlobalKnownHostsFile=/dev/null)

  make_host_module "$module_file" "$bootstrap_admin"

  if [ -n "$ssh_identity_file" ]; then
    ssh_cmd+=( -i "$ssh_identity_file" )
    scp_cmd+=( -i "$ssh_identity_file" )
  fi

  "${ssh_cmd[@]}" "$target_host" 'mkdir -p /etc/nixos'
  "${scp_cmd[@]}" "$module_file" "$remote_target"

  printf 'Infecting %s onto %s\n' "$host_name" "$target_host"
  "${ssh_cmd[@]}" "$target_host" \
    "umount /boot/efi 2>/dev/null || true; curl -fsSL https://raw.githubusercontent.com/elitak/nixos-infect/36f48d8feb89ca508261d7390355144fc0048932/nixos-infect | env NIX_INSTALL_URL='$pinned_nix_install_url' PROVIDER=digitalocean doNetConf=y NIX_CHANNEL=nixos-24.05 NIXOS_IMPORT=./host-bootstrap.nix bash -x" || true

  printf 'Waiting for %s to reboot into NixOS\n' "$host_name"
  for try in $(seq 1 60); do
    if "${ssh_cmd[@]}" -o ConnectTimeout=5 "$admin_target" 'grep -q "^ID=nixos" /etc/os-release' 2>/dev/null; then
      break
    fi
    sleep 5
  done

  if ! "${ssh_cmd[@]}" -o ConnectTimeout=5 "$admin_target" 'grep -q "^ID=nixos" /etc/os-release' 2>/dev/null; then
    printf 'Bootstrap failed for %s: host did not come back as NixOS with %s access\n' "$host_name" "$bootstrap_admin" >&2
    failures+=( "$host_name" )
    rm -rf "$work_dir"
    return 1
  fi

  printf 'Finalizing network config on %s\n' "$host_name"
  "${ssh_cmd[@]}" "$admin_target" '
    sudo sed -i "/defaultGateway6 = {/,/};/d" /etc/nixos/networking.nix 2>/dev/null || true
    sudo sed -i "/ipv6.routes = \[ { address = \"\"; prefixLength = 128; } \];/d" /etc/nixos/networking.nix 2>/dev/null || true
    sudo nixos-rebuild switch
  '

  if ! "${ssh_cmd[@]}" "$admin_target" 'sudo -n true >/dev/null && test "$(systemctl is-system-running || true)" = running' 2>/dev/null; then
    printf 'Bootstrap verification failed for %s: host is not healthy after first switch\n' "$host_name" >&2
    failures+=( "$host_name" )
    rm -rf "$work_dir"
    return 1
  fi

  printf 'Bootstrap verified for %s\n' "$host_name"

  rm -rf "$work_dir"
}

if [ -n "${main_target:-}" ]; then
  run_bootstrap main-wiki "$main_target" || true
fi
if [ -n "${replica_target:-}" ]; then
  run_bootstrap replica-wiki "$replica_target" || true
fi

if [ "${#failures[@]}" -ne 0 ]; then
  printf '\nBootstrap failed for: %s\n' "${failures[*]}" >&2
  exit 1
fi

printf '\nBootstrap complete. The hosts should now be reachable as NixOS systems over public SSH as %s.\n' "$bootstrap_admin"

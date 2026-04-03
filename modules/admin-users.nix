{
  lib,
  pkgs,
  siteConfig,
  ...
}:
let
  managedKeyDir = "/var/lib/noisebridge-admin-keys";

  explicitKeysFor = userCfg: (userCfg.sshKeys or [ ]) ++ (userCfg.openssh.authorizedKeys.keys or [ ]);

  githubUsersFor = userCfg: userCfg.githubUsers or [ ];

  adminUsersWithGithubKeys = lib.filterAttrs (
    _: userCfg: githubUsersFor userCfg != [ ]
  ) siteConfig.adminUsers;
in
{
  users.users = lib.mapAttrs (
    userName: userCfg:
    let
      explicitKeys = explicitKeysFor userCfg;
      existingAuthorizedKeys = userCfg.openssh.authorizedKeys or { };
    in
    (lib.removeAttrs userCfg [
      "sshKeys"
      "githubUsers"
    ])
    // {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      linger = true;
      openssh.authorizedKeys = existingAuthorizedKeys // {
        keys = explicitKeys;
      };
    }
  ) siteConfig.adminUsers;

  # Keep the normal Nix-managed authorized_keys path, then add a runtime-managed
  # path for GitHub-derived keys so deploy-time fetches do not need pure evaluation.
  services.openssh.settings.AuthorizedKeysFile = ".ssh/authorized_keys /etc/ssh/authorized_keys.d/%u ${managedKeyDir}/%u.keys";

  systemd.tmpfiles.rules = [ "d ${managedKeyDir} 0755 root root -" ];

  system.activationScripts.adminGithubAuthorizedKeys = lib.stringAfter [ "users" ] (
    ''
      install -d -m 0755 ${managedKeyDir}
      staging_dir="$(${pkgs.coreutils}/bin/mktemp -d)"
      trap '${pkgs.coreutils}/bin/rm -rf "$staging_dir"' EXIT
    ''
    + lib.concatMapStrings (
      userName:
      let
        githubUsers = githubUsersFor siteConfig.adminUsers.${userName};
        stagedKeyFile = "$" + "{staging_dir}/${userName}.keys";
      in
      ''
        tmp_file="$(${pkgs.coreutils}/bin/mktemp)"
        trap '${pkgs.coreutils}/bin/rm -rf "$staging_dir" "$tmp_file"' EXIT
        ${lib.concatMapStrings (githubUser: ''
          ${pkgs.curl}/bin/curl -fsSL ${lib.escapeShellArg "https://github.com/${githubUser}.keys"} >> "$tmp_file"
          printf '\n' >> "$tmp_file"
        '') githubUsers}
        # Stage the full fetched key set first so a fetch failure cannot delete
        # the currently-authorized GitHub keys for existing admins.
        ${pkgs.coreutils}/bin/sort -u "$tmp_file" | ${pkgs.gnused}/bin/sed '/^$/d' > ${lib.escapeShellArg stagedKeyFile}
        ${pkgs.coreutils}/bin/chmod 0644 ${lib.escapeShellArg stagedKeyFile}
        ${pkgs.coreutils}/bin/rm -f "$tmp_file"
      ''
    ) (builtins.attrNames adminUsersWithGithubKeys)
    + ''
      # Replace the managed GitHub key set atomically once every fetch succeeded.
      ${pkgs.findutils}/bin/find ${managedKeyDir} -maxdepth 1 -type f -name '*.keys' -delete
      ${pkgs.findutils}/bin/find "$staging_dir" -maxdepth 1 -type f -name '*.keys' -exec ${pkgs.coreutils}/bin/mv {} ${managedKeyDir}/ \;
      trap - EXIT
      ${pkgs.coreutils}/bin/rm -rf "$staging_dir"
    ''
  );

  security.sudo.wheelNeedsPassword = false;
}

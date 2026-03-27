{ pkgs, ... }:
{
  age.identityPaths = [ "/var/lib/agenix/host.age" ];

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    auto-optimise-store = true;
    max-jobs = "auto";
    cores = 0;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  services.journald.storage = "persistent";

  services.timesyncd.enable = true;

  system.activationScripts.restart-logind.text = ''
    systemctl restart systemd-logind.service || true
  '';

  systemd.tmpfiles.rules = [
    "d /var/lib/agenix 0700 root root -"
    "z /var/lib/agenix/host.age 0400 root root -"
  ];

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    jq
    rsync
    mariadb.client
  ];
}

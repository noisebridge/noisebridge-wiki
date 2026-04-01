{ hostMeta, siteConfig, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostMeta.nixosName;

  system.stateVersion = "24.11";
}

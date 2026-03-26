{ hostMeta, siteConfig, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = hostMeta.nixosName;
  networking.domain = siteConfig.baseDomain;

  system.stateVersion = "24.11";
}

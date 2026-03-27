{ lib, siteConfig, ... }:
{
  users.users = lib.mapAttrs (
    _: userCfg:
    {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      linger = true;
    }
    // userCfg
  ) siteConfig.adminUsers;

  security.sudo.wheelNeedsPassword = false;
}

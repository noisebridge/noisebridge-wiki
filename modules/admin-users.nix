{ lib, siteConfig, ... }:
{
  users.users = lib.mapAttrs (
    _: userCfg:
    {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    }
    // userCfg
  ) siteConfig.adminUsers;

  security.sudo.wheelNeedsPassword = false;
}

{ ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      AllowAgentForwarding = false;
      AllowGroups = [ "wheel" ];
      AllowTcpForwarding = false;
      ClientAliveCountMax = 2;
      ClientAliveInterval = 300;
      KbdInteractiveAuthentication = false;
      LoginGraceTime = 20;
      MaxAuthTries = 3;
      MaxSessions = 4;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PermitTunnel = false;
      PermitUserEnvironment = false;
      StreamLocalBindUnlink = false;
      X11Forwarding = false;
    };
  };
}

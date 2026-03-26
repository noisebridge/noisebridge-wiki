{
  config,
  hostMeta,
  lib,
  pkgs,
  siteConfig,
  ...
}:
let
  wikiDomain = hostMeta.publicDomain;
  mediawikiPackages = import ../modules/mediawiki-packages.nix { inherit pkgs; };
  mediawikiDbPassword = config.age.secrets.mysql-mediawiki.path;
  mediawikiReplicationPassword = config.age.secrets.mysql-replication.path;
  mediawikiAdminPassword = config.age.secrets.mediawiki-admin-password.path;
  mediawikiSecretKey = config.age.secrets.mediawiki-secret-key.path;
  mediawikiUpgradeKey = config.age.secrets.mediawiki-upgrade-key.path;
in
{
  imports = [ ./common.nix ];

  age.secrets.mysql-mediawiki = {
    file = ../secrets/shared/mysql-mediawiki.age;
    owner = "mediawiki";
    group = "mediawiki";
  };

  age.secrets.mysql-replication = {
    file = ../secrets/shared/mysql-replication.age;
    owner = "mysql";
    group = "mysql";
  };

  age.secrets.mediawiki-admin-password = {
    file = ../secrets/shared/mediawiki-admin-password.age;
    owner = "mediawiki";
    group = "mediawiki";
  };

  age.secrets.mediawiki-secret-key = {
    file = ../secrets/shared/mediawiki-secret-key.age;
    owner = "mediawiki";
    group = "mediawiki";
  };

  age.secrets.mediawiki-upgrade-key = {
    file = ../secrets/shared/mediawiki-upgrade-key.age;
    owner = "mediawiki";
    group = "mediawiki";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ siteConfig.database.name ];
    settings.mysqld = {
      bind-address = "127.0.0.1";
      character-set-server = "utf8mb4";
      collation-server = "utf8mb4_unicode_ci";
      innodb_file_per_table = 1;
      max_allowed_packet = "64M";
      server-id = 2;
      relay-log = "mysql-relay-bin";
      read-only = true;
      log-slave-updates = true;
      skip-slave-start = false;
    };
  };

  systemd.services.mediawiki-db-setup = {
    description = "Create MediaWiki database user on replica";
    after = [
      "run-agenix.d.mount"
      "mysql.service"
    ];
    requires = [
      "run-agenix.d.mount"
      "mysql.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    before = [ "mediawiki-init.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      password="$(tr -d '\n' < ${mediawikiDbPassword})"

      ${pkgs.mariadb}/bin/mariadb --protocol=socket -uroot <<SQL
      CREATE USER IF NOT EXISTS '${siteConfig.database.mediawikiUser}'@'localhost' IDENTIFIED BY '${"$"}password';
      ALTER USER '${siteConfig.database.mediawikiUser}'@'localhost' IDENTIFIED BY '${"$"}password';
      GRANT ALL PRIVILEGES ON ${siteConfig.database.name}.* TO '${siteConfig.database.mediawikiUser}'@'localhost';
      FLUSH PRIVILEGES;
      SQL
    '';
  };

  systemd.services.mediawiki-init.wantedBy = lib.mkForce [ ];

  systemd.services.mysql-replication-replica = {
    description = "Configure MariaDB replica replication";
    after = [
      "run-agenix.d.mount"
      "mysql.service"
    ];
    requires = [
      "run-agenix.d.mount"
      "mysql.service"
    ];
    before = [ "mediawiki-init.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      password="$(tr -d '\n' < ${mediawikiReplicationPassword})"
      status="$(${pkgs.mariadb}/bin/mariadb --protocol=socket -uroot -e "SHOW SLAVE STATUS\\G" || true)"

      if printf '%s\n' "$status" | grep -q "Master_Host: ${siteConfig.hosts.primary.publicIpv4}"; then
        ${pkgs.mariadb}/bin/mariadb --protocol=socket -uroot -e "START SLAVE;"
        exit 0
      fi

      while :; do
        master_status="$(${pkgs.mariadb}/bin/mariadb --batch --skip-column-names -h ${siteConfig.hosts.primary.publicIpv4} -u ${siteConfig.database.replicationUser} --password="$password" -e "SHOW MASTER STATUS" 2>/dev/null || true)"
        if [ -n "$master_status" ]; then
          break
        fi
        sleep 2
      done

      set -- $master_status
      master_log_file="$1"
      master_log_pos="$2"

      ${pkgs.mariadb}/bin/mariadb --protocol=socket -uroot <<SQL
      STOP SLAVE;
      RESET SLAVE ALL;
      CHANGE MASTER TO MASTER_HOST='${siteConfig.hosts.primary.publicIpv4}', MASTER_USER='${siteConfig.database.replicationUser}', MASTER_PASSWORD='${"$"}password', MASTER_PORT=3306, MASTER_LOG_FILE='${"$"}master_log_file', MASTER_LOG_POS=${"$"}master_log_pos, MASTER_CONNECT_RETRY=10;
      START SLAVE;
      SQL
    '';
  };

  services.mediawiki = {
    enable = true;
    name = siteConfig.wikiName;
    url = "https://${wikiDomain}";
    webserver = "none";
    passwordFile = mediawikiAdminPassword;
    passwordSender = siteConfig.mediawiki.passwordSender;
    uploadsDir = siteConfig.mediawiki.uploadsDir;
    database = {
      type = "mysql";
      createLocally = false;
      host = "127.0.0.1";
      port = 3306;
      name = siteConfig.database.name;
      user = siteConfig.database.mediawikiUser;
      passwordFile = mediawikiDbPassword;
    };
    skins = lib.mkForce {
      Vector = mediawikiPackages.skins.Vector;
    };
    extraConfig = ''
      $wgScriptPath = "${siteConfig.mediawiki.scriptPath}";
      $wgArticlePath = "${siteConfig.mediawiki.articlePath}";
      $wgUsePathInfo = true;
      $wgEmergencyContact = "${siteConfig.mediawiki.emergencyContact}";
      $wgPasswordSender = "${siteConfig.mediawiki.passwordSender}";
      $wgLanguageCode = "en";
      $wgSecretKey = trim( file_get_contents( "${mediawikiSecretKey}" ) );
      $wgUpgradeKey = trim( file_get_contents( "${mediawikiUpgradeKey}" ) );
      $wgEnableUploads = false;
      $wgDefaultSkin = "vector-2022";
      $wgReadOnly = '${siteConfig.mediawiki.readOnlyMessage}';
    '';
  };

  services.phpfpm.pools.mediawiki.settings.listen = "127.0.0.1:9000";

  services.caddy = {
    enable = true;
    virtualHosts.${wikiDomain}.extraConfig = ''
      encode zstd gzip
      root * ${config.services.mediawiki.finalPackage}/share/mediawiki

      redir / /wiki 308

      @wikiRoot path /wiki /wiki/
      rewrite @wikiRoot /index.php?title=Main_Page

      @wikiPage path_regexp wikiPage ^/wiki/(.+)$
      rewrite @wikiPage /index.php?title={re.wikiPage.1}

      php_fastcgi 127.0.0.1:9000
      file_server {
        hide *.php
      }
    '';
  };

  systemd.tmpfiles.rules = [
    "d /srv/mediawiki 0755 root root -"
    "d ${siteConfig.mediawiki.uploadsDir} 0750 mediawiki mediawiki -"
  ];
}

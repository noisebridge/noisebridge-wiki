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
  enabledExtensions = lib.getAttrs siteConfig.mediawiki.enabledExtensions mediawikiPackages.extensions;
  mediawikiDbPassword = config.age.secrets.mysql-mediawiki.path;
  mediawikiReplicationPassword = config.age.secrets.mysql-replication.path;
  mediawikiAdminPassword = config.age.secrets.mediawiki-admin-password.path;
  mediawikiRecaptchaSecretKey = config.age.secrets.mediawiki-recaptcha-secret-key.path;
  mediawikiRecaptchaSiteKey = config.age.secrets.mediawiki-recaptcha-site-key.path;
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

  age.secrets.mediawiki-recaptcha-secret-key = {
    file = ../secrets/shared/mediawiki-recaptcha-secret-key.age;
    owner = "mediawiki";
    group = "mediawiki";
  };

  age.secrets.mediawiki-recaptcha-site-key = {
    file = ../secrets/shared/mediawiki-recaptcha-site-key.age;
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
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s ${siteConfig.hosts.replica.publicIpv4} --dport 3306 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s ${siteConfig.hosts.replica.publicIpv4} --dport 3306 -j nixos-fw-accept || true
  '';

  services.memcached.enable = true;

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ siteConfig.database.name ];
    settings.mysqld = {
      bind-address = "0.0.0.0";
      character-set-server = "utf8mb4";
      collation-server = "utf8mb4_unicode_ci";
      innodb_file_per_table = 1;
      max_allowed_packet = "64M";
      server-id = 1;
      log-bin = "mysql-bin";
      binlog-format = "ROW";
      expire-logs-days = 7;
      sync-binlog = 1;
    };
  };

  systemd.services.mediawiki-db-setup = {
    description = "Create MediaWiki database user";
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
      password="$(tr -d '\n' < ${mediawikiDbPassword})"

      ${pkgs.mariadb}/bin/mariadb --protocol=socket -uroot <<SQL
      CREATE USER IF NOT EXISTS '${siteConfig.database.mediawikiUser}'@'localhost' IDENTIFIED BY '${"$"}password';
      ALTER USER '${siteConfig.database.mediawikiUser}'@'localhost' IDENTIFIED BY '${"$"}password';
      GRANT ALL PRIVILEGES ON ${siteConfig.database.name}.* TO '${siteConfig.database.mediawikiUser}'@'localhost';
      FLUSH PRIVILEGES;
      SQL
    '';
  };

  systemd.services.mediawiki-init = {
    requires = [ "mediawiki-db-setup.service" ];
    after = [ "mediawiki-db-setup.service" ];
  };

  systemd.services.mysql-replication-primary = {
    description = "Create MariaDB replication user";
    after = [
      "run-agenix.d.mount"
      "mysql.service"
    ];
    requires = [
      "run-agenix.d.mount"
      "mysql.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      password="$(tr -d '\n' < ${mediawikiReplicationPassword})"

      ${pkgs.mariadb}/bin/mariadb --protocol=socket -uroot <<SQL
      CREATE USER IF NOT EXISTS '${siteConfig.database.replicationUser}'@'${siteConfig.hosts.replica.publicIpv4}' IDENTIFIED BY '${"$"}password';
      ALTER USER '${siteConfig.database.replicationUser}'@'${siteConfig.hosts.replica.publicIpv4}' IDENTIFIED BY '${"$"}password';
      GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '${siteConfig.database.replicationUser}'@'${siteConfig.hosts.replica.publicIpv4}';
      FLUSH PRIVILEGES;
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
    phpPackage = pkgs.php83.buildEnv {
      extensions =
        { enabled, all }:
        enabled
        ++ (with all; [
          apcu
          luasandbox
          memcached
        ]);
    };
    database = {
      type = "mysql";
      createLocally = false;
      host = "127.0.0.1";
      port = 3306;
      name = siteConfig.database.name;
      user = siteConfig.database.mediawikiUser;
      passwordFile = mediawikiDbPassword;
    };
    path = with pkgs; [
      diffutils
      ffmpeg
      imagemagick
    ];
    skins = lib.mkForce {
      CologneBlue = mediawikiPackages.skins.CologneBlue;
      MinervaNeue = mediawikiPackages.skins.MinervaNeue;
      Modern = mediawikiPackages.skins.Modern;
      MonoBook = mediawikiPackages.skins.MonoBook;
      Timeless = mediawikiPackages.skins.Timeless;
      Vector = mediawikiPackages.skins.Vector;
    };
    extensions = enabledExtensions;
    extraConfig = ''
      $wgScriptPath = "${siteConfig.mediawiki.scriptPath}";
      $wgArticlePath = "${siteConfig.mediawiki.articlePath}";
      $wgUsePathInfo = true;
      $wgResourceBasePath = $wgScriptPath;
      $wgLogo = "/img/nb-logo-131.png";
      $wgFavicon = "/img/favicon.ico";

      $wgEnableEmail = true;
      $wgEnableUserEmail = true;
      $wgEmergencyContact = "${siteConfig.mediawiki.emergencyContact}";
      $wgPasswordSender = "${siteConfig.mediawiki.passwordSender}";
      $wgEnotifUserTalk = true;
      $wgEnotifWatchlist = true;
      $wgEmailAuthentication = true;

      $wgDBprefix = "${siteConfig.database.tablePrefix}";
      $wgDBTableOptions = "ENGINE=InnoDB, DEFAULT CHARSET=binary";
      $wgDBmysql5 = false;

      $wgMainCacheType = CACHE_MEMCACHED;
      $wgMessageCacheType = CACHE_MEMCACHED;
      $wgParserCacheType = CACHE_MEMCACHED;
      $wgMemCachedServers = [ "127.0.0.1:11211" ];
      $wgEnableSidebarCache = true;
      $wgSessionsInObjectCache = true;
      $wgSessionCacheType = CACHE_MEMCACHED;

      $wgEnableUploads = true;
      $wgUploadDirectory = "${siteConfig.mediawiki.uploadsDir}";
      $wgUploadPath = "${siteConfig.mediawiki.uploadPath}";
      $wgUseImageMagick = true;
      $wgUseImageResize = true;
      $wgImageMagickConvertCommand = "${pkgs.imagemagick}/bin/convert";
      $wgUseInstantCommons = true;

      $wgShellLocale = "en_US.utf8";
      $wgLanguageCode = "en";
      $wgLocaltimezone = "US/Pacific";
      date_default_timezone_set( $wgLocaltimezone );

      $wgSecretKey = trim( file_get_contents( "${mediawikiSecretKey}" ) );
      $wgAuthenticationTokenVersion = "1";
      $wgUpgradeKey = trim( file_get_contents( "${mediawikiUpgradeKey}" ) );

      $wgRightsUrl = "https://creativecommons.org/licenses/by-nc-sa/4.0/";
      $wgRightsText = "Creative Commons Attribution-NonCommercial-ShareAlike";
      $wgRightsIcon = "$wgResourceBasePath/resources/assets/licenses/cc-by-nc-sa.png";
      $wgDiff3 = "${pkgs.diffutils}/bin/diff3";

      $wgDefaultSkin = "vector";
      $wgVectorDefaultSkinVersionForExistingAccounts = "1";
      $wgVectorDefaultSkinVersionForNewAccounts = "1";
      $wgVectorShowSkinPreferences = true;

      $wgUseGzip = true;
      $wgUseFileCache = false;
      $wgFileCacheDirectory = "${siteConfig.mediawiki.fileCacheDir}";
      $wgShowIPinHeader = false;
      $wgCdnMaxAge = 7200;

      $wgCaptchaQuestions = [
        'What is the guiding principle of Noisebridge?' => [ 'be excellent' ],
      ];
      $wgCaptchaWhitelistIP = [ '192.195.83.130' ];
      $wgRateLimitsExcludedIPs = [ '192.195.83.128/29' ];
      $wgGroupPermissions['user']['noratelimit'] = true;
      $wgCaptchaClass = 'ReCaptchaNoCaptcha';
      $wgReCaptchaSiteKey = trim( file_get_contents( "${mediawikiRecaptchaSiteKey}" ) );
      $wgReCaptchaSecretKey = trim( file_get_contents( "${mediawikiRecaptchaSecretKey}" ) );
      $wgReCaptchaSendRemoteIP = false;
      $ceAllowConfirmedEmail = true;
      $wgCaptchaTriggers['edit'] = true;
      $wgCaptchaTriggers['create'] = true;
      $wgCaptchaTriggers['addurl'] = true;
      $wgCaptchaTriggers['createaccount'] = true;
      $wgCaptchaTriggers['badlogin'] = true;

      $wgGroupPermissions['*']['createpage'] = false;
      $wgGroupPermissions['user']['createpage'] = false;
      $wgGroupPermissions['*']['createtalk'] = false;
      $wgGroupPermissions['user']['createtalk'] = false;
      $wgGroupPermissions['autoconfirmed']['createpage'] = true;
      $wgGroupPermissions['autoconfirmed']['createtalk'] = true;
      $wgGroupPermissions['*']['move'] = false;
      $wgGroupPermissions['user']['move'] = false;
      $wgGroupPermissions['autoconfirmed']['move'] = true;
      $wgGroupPermissions['*']['upload'] = false;
      $wgGroupPermissions['user']['upload'] = false;
      $wgGroupPermissions['autoconfirmed']['upload'] = true;
      $wgGroupPermissions['*']['skipcaptcha'] = false;
      $wgGroupPermissions['user']['skipcaptcha'] = false;
      $wgGroupPermissions['autoconfirmed']['skipcaptcha'] = true;
      $wgGroupPermissions['emailconfirmed']['skipcaptcha'] = true;
      $wgGroupPermissions['bot']['skipcaptcha'] = true;
      $wgGroupPermissions['sysop']['skipcaptcha'] = true;
      $wgGroupPermissions['confirmed'] = $wgGroupPermissions['autoconfirmed'];
      $wgAutoConfirmCount = 5;
      $wgAutoConfirmAge = 86400 * 3;
      $wgAutopromote = [
        "autoconfirmed" => [ "&", [ APCOND_EDITCOUNT, &$wgAutoConfirmCount ], [ APCOND_AGE, &$wgAutoConfirmAge ], APCOND_EMAILCONFIRMED ],
      ];

      $wgFileExtensions[] = 'pdf';
      $wgFileExtensions[] = 'svg';

      $wgGroupPermissions['sysop']['checkuser'] = true;
      $wgGroupPermissions['sysop']['checkuser-log'] = true;
      $wgGroupPermissions['sysop']['investigate'] = true;
      $wgGroupPermissions['sysop']['checkuser-temporary-account'] = true;
      $wgGroupPermissions['interface-admin']['gadgets-edit'] = true;
      $wgGroupPermissions['interface-admin']['gadgets-definition-edit'] = true;
      $wgPopupsVirtualPageViews = true;
      $wgPopupsReferencePreviewsBetaFeature = false;
      $wgPopupsOptInDefaultState = 1;
      $wgGroupPermissions['*']['createaccount'] = false;
      $wgGroupPermissions['bureaucrat']['createaccount'] = true;
      $wgAllowUserJs = true;
      $wgAllowUserCss = true;
      $wgGroupPermissions['sysop']['interwiki'] = true;
      $wgGroupPermissions['bureaucrat']['invitesignup'] = true;
      $wgGroupPermissions['invitesignup']['invitesignup'] = true;
      $wgISGroupsRequired = [ 'invitedIS' ];
      $wgScribuntoDefaultEngine = 'luasandbox';
      $wgGroupPermissions['user']['writeapi'] = true;
      $wgForeignFileRepos[] = [
        'class' => ForeignAPIRepo::class,
        'name' => 'commonswiki',
        'apibase' => 'https://commons.wikimedia.org/w/api.php',
        'hashLevels' => 2,
        'fetchDescription' => true,
        'descriptionCacheExpiry' => 43200,
        'apiThumbCacheExpiry' => 86400,
      ];
    '';
  };

  services.phpfpm.pools.mediawiki.settings.listen = "127.0.0.1:9000";

  services.caddy = {
    enable = true;
    virtualHosts.${wikiDomain}.extraConfig = ''
      encode zstd gzip
      root * ${config.services.mediawiki.finalPackage}/share/mediawiki

      handle_path /images/* {
        root * ${siteConfig.mediawiki.uploadsDir}
        file_server
      }

      handle_path /img/* {
        root * ${siteConfig.mediawiki.staticAssetsDir}
        file_server
      }

      @favicon path /favicon.ico
      handle @favicon {
        root * ${siteConfig.mediawiki.staticAssetsDir}
        file_server
      }

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
    "d ${siteConfig.mediawiki.staticAssetsDir} 0755 mediawiki mediawiki -"
    "d ${siteConfig.mediawiki.fileCacheDir} 0755 mediawiki mediawiki -"
  ];
}

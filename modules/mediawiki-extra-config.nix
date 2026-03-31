{
  pkgs,
  siteConfig,
  mediawikiSecretKey,
  mediawikiUpgradeKey,
  mediawikiRecaptchaSiteKey,
  mediawikiRecaptchaSecretKey,
}:
{
  extraLines ? "",
}:
''
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

    wfLoadExtension( 'ConfirmEdit/ReCaptchaNoCaptcha' );

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
  ${extraLines}
''

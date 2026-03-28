let
  readRecipient = path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile path);

  adminKeys = [
    # Jet
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE40ISu3ydCqfdpb26JYD5cIN0Fu0id/FDS+xjB5zpqu jetthomaspham@gmail.com"
  ];
  mainWiki = readRecipient ./hosts/main-wiki.age.pub;
  replicaWiki = readRecipient ./hosts/replica-wiki.age.pub;

  allHosts = [
    mainWiki
    replicaWiki
  ];
in
{
  "shared/mysql-mediawiki.age".publicKeys = adminKeys ++ allHosts;
  "shared/mysql-replication.age".publicKeys = adminKeys ++ allHosts;
  "shared/mediawiki-admin-password.age".publicKeys = adminKeys ++ allHosts;
  "shared/mediawiki-recaptcha-secret-key.age".publicKeys = adminKeys ++ allHosts;
  "shared/mediawiki-recaptcha-site-key.age".publicKeys = adminKeys ++ allHosts;
  "shared/mediawiki-secret-key.age".publicKeys = adminKeys ++ allHosts;
  "shared/mediawiki-upgrade-key.age".publicKeys = adminKeys ++ allHosts;
}

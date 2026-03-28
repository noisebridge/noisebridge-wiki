{ pkgs }:
let
  fetchRelExtension =
    name: hash:
    pkgs.fetchzip {
      url = "https://github.com/wikimedia/mediawiki-extensions-${name}/archive/refs/heads/REL1_45.tar.gz";
      inherit hash;
    };
in
{
  extensions = {
    AdminLinks = fetchRelExtension "AdminLinks" "sha256-CBIxASBVcdQgL6Iw6OtIxWRi0tfdojajNqY3U4w3b+o=";
    BetaFeatures = fetchRelExtension "BetaFeatures" "sha256-N/xiTlrzOb8mtt7mgtQ9iwrLJu8ddt8JwN+99EGfwXI=";
    CategoryTree = fetchRelExtension "CategoryTree" "sha256-y4zCt0vNrbN2nNvDvXjHFQ6BH/P2nSTHKCwY1bWil2A=";
    CharInsert = fetchRelExtension "CharInsert" "sha256-KlSh5ZYnF4IqGClA/1Oj2PAoUM4PAFh0U1yUHSPS18Y=";
    CheckUser = fetchRelExtension "CheckUser" "sha256-b/3TZdRIEg7jwWynNHjluRyS0rwdtbY1ahZLALq4tWc=";
    ConfirmAccount = fetchRelExtension "ConfirmAccount" "sha256-8sXziggkquQdvXuUD/asbhVQglLiFzuYCVe9FePR9NY=";
    ConfirmEdit = fetchRelExtension "ConfirmEdit" "sha256-GQb5qe/T0gmFZJ55dKQKYZUoKlk+Iak8pr8kDOpUeHk=";
    Gadgets = fetchRelExtension "Gadgets" "sha256-vg3xVdgMPg7YqoFTsqHfvUYdy9rNFpBvv/CVKTdeIF4=";
    ImageMap = fetchRelExtension "ImageMap" "sha256-sId/eXP4r2eJvUVuGsglMyYm6vFjzwqSOml6u6ujIcU=";
    Interwiki = fetchRelExtension "Interwiki" "sha256-Wk2DvBGigv2LIzOafUiIE5Cc62W+enIG3yVVczRKZyw=";
    InviteSignup = fetchRelExtension "InviteSignup" "sha256-ZTomHYQ/TGanb0/nsegXyYy2hYF+bMe1cLmmKevFJSw=";
    MultimediaViewer = fetchRelExtension "MultimediaViewer" "sha256-1zJbeHj8kbVpk/W04P8r1yQNcdal1h82l2orlswNRcA=";
    Nuke = fetchRelExtension "Nuke" "sha256-HXHhmDB+uZW7s0hs1j3YNwoMoXAjF27KRrnw3V8t5L4=";
    PageImages = fetchRelExtension "PageImages" "sha256-HKv4zj9yIDwIcJ+Y+YBMPK6IjaJ5lQj9R9qJg/h5DFk=";
    ParserFunctions = fetchRelExtension "ParserFunctions" "sha256-A5U3cjMN+Cem1irork4q9Y64XK9qFjxpD9btBT3mjPc=";
    Popups = fetchRelExtension "Popups" "sha256-2pTf+tlaMv3zc0st8yYMPNRr2lQKO/ZgQCwQeWX4/cY=";
    Renameuser = fetchRelExtension "Renameuser" "sha256-39VsqhSuKfOnL/6hwfeFyHsxSJr/VTnJE5BlfCP+2MA=";
    Scribunto = fetchRelExtension "Scribunto" "sha256-an9spl7pbQq2j+6EAVAssJf45RKUx6gR2syhtijixiM=";
    TextExtracts = fetchRelExtension "TextExtracts" "sha256-BdRlHwR3Ws5qVqv4+6P/xtXIc2x7UKv1pbWkkFj4sWg=";
    VisualEditor = fetchRelExtension "VisualEditor" "sha256-i/6Psyqxd5bQYpXEeQMlS9/pvUeidErOaaVK+fAsjpw=";
    QRLite = pkgs.fetchzip {
      url = "https://github.com/gesinn-it/QRLite/archive/refs/heads/master.zip";
      hash = "sha256-2lDe2gkHVZcUc7O15xqLn8C3NHlNA3ABtZtXnosK8G8=";
    };
    EmbedVideo = pkgs.fetchzip {
      url = "https://gitlab.com/HydraWiki/extensions/EmbedVideo/-/archive/v2.9.0/EmbedVideo-v2.9.0.zip";
      hash = "sha256-YW/bTJ0lT+obmhj2DStQs5WngonLQhC+3pt2V//V7+A=";
    };
  };

  skins = {
    Vector = pkgs.fetchzip {
      url = "https://github.com/wikimedia/mediawiki-skins-Vector/archive/refs/heads/REL1_45.tar.gz";
      hash = "sha256-hlZNbeDcFlAfhPO1T/A/1EcgIr//S7t7+BsU4GqsrAo=";
    };
  };
}

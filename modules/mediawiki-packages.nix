{ pkgs }:
let
  fetchGitHubArchive =
    repo: rev: hash:
    pkgs.fetchzip {
      url = "https://github.com/${repo}/archive/${rev}.tar.gz";
      inherit hash;
    };

  fetchGitHubZipArchive =
    repo: rev: hash:
    pkgs.fetchzip {
      url = "https://github.com/${repo}/archive/${rev}.zip";
      inherit hash;
    };

  fetchGitilesArchive =
    path: rev: hash:
    pkgs.fetchzip {
      url = "https://gerrit.wikimedia.org/r/plugins/gitiles/${path}/+archive/${rev}.tar.gz";
      inherit hash;
      stripRoot = false;
    };

  fetchWikimediaExtension =
    name: rev: hash:
    fetchGitHubArchive "wikimedia/mediawiki-extensions-${name}" rev hash;

  fetchWikimediaSkin =
    name: rev: hash:
    fetchGitHubArchive "wikimedia/mediawiki-skins-${name}" rev hash;
in
{
  extensions = {
    AdminLinks =
      fetchWikimediaExtension "AdminLinks" "45eb65a5c439dd8dbf5656eccb277f0cefe9a12a"
        "sha256-CBIxASBVcdQgL6Iw6OtIxWRi0tfdojajNqY3U4w3b+o=";
    BetaFeatures =
      fetchWikimediaExtension "BetaFeatures" "635be7f11808085a38071dcaf82f0becfd018826"
        "sha256-N/xiTlrzOb8mtt7mgtQ9iwrLJu8ddt8JwN+99EGfwXI=";
    CategoryTree =
      fetchWikimediaExtension "CategoryTree" "f1b16bb3f187ce6cf5bbd36e22bbf592f2ba3c50"
        "sha256-y4zCt0vNrbN2nNvDvXjHFQ6BH/P2nSTHKCwY1bWil2A=";
    CharInsert =
      fetchWikimediaExtension "CharInsert" "ac7eb1b0f965cde72ae9b15f0ad9e531b6518f6c"
        "sha256-KlSh5ZYnF4IqGClA/1Oj2PAoUM4PAFh0U1yUHSPS18Y=";
    CheckUser =
      fetchWikimediaExtension "CheckUser" "5148f833325ac9dec693580239ab315915d92d99"
        "sha256-b/3TZdRIEg7jwWynNHjluRyS0rwdtbY1ahZLALq4tWc=";
    Cite =
      fetchWikimediaExtension "Cite" "deb4de4502b807fa59b2b82714783d5c3420be31"
        "sha256-/5CxElCZkCL2ex7w3I4MoNa8GnnhLxKY7js6gYS3rrs=";
    CodeEditor =
      fetchWikimediaExtension "CodeEditor" "d78cdd11617bbe476bbad2e5379e17b583a25f54"
        "sha256-rvNb7mpUPzJCeLqLsIi3qqXj5+sX9UxHmbgdEm9yhaw=";
    ConfirmAccount =
      fetchWikimediaExtension "ConfirmAccount" "0c0f17c483108f3c14da620d70d4498bb889f22c"
        "sha256-8sXziggkquQdvXuUD/asbhVQglLiFzuYCVe9FePR9NY=";
    ConfirmEdit =
      fetchWikimediaExtension "ConfirmEdit" "1761d61ce02c6854ee49495d45fb5c70e897feb8"
        "sha256-GQb5qe/T0gmFZJ55dKQKYZUoKlk+Iak8pr8kDOpUeHk=";
    Echo =
      fetchWikimediaExtension "Echo" "84b05e44058baa0096cc9040d6abefa8cdf5551c"
        "sha256-10FnVUq7J4POlj8r3WvAE5ZG7+t5S79GSGIs3tQi1OU=";
    Gadgets =
      fetchWikimediaExtension "Gadgets" "888443ff0ea365b7ef7cea51f872b473cbb55bd7"
        "sha256-vg3xVdgMPg7YqoFTsqHfvUYdy9rNFpBvv/CVKTdeIF4=";
    Graph =
      fetchGitilesArchive "mediawiki/extensions/Graph" "bd416299450c4cdd608563ad2faebb43cde9a3db"
        "sha256-VgOA0VROh/Vtnb54+BgApVpsckcCalN6wh+Fc69zQII=";
    ImageMap =
      fetchWikimediaExtension "ImageMap" "3deaecb20f7ca9c7df79ebce285e4d87bd6b4e67"
        "sha256-sId/eXP4r2eJvUVuGsglMyYm6vFjzwqSOml6u6ujIcU=";
    InputBox =
      fetchWikimediaExtension "InputBox" "8f8bbfca01a554bfe2493161711b0f03702fdb88"
        "sha256-VVp03d6Q7q+gAYemOjj9EYHH3QUfco3VoqSHwLYSp48=";
    Interwiki =
      fetchWikimediaExtension "Interwiki" "6e079c7619426d063ae51cf1f866197ad1eb5d1a"
        "sha256-Wk2DvBGigv2LIzOafUiIE5Cc62W+enIG3yVVczRKZyw=";
    InviteSignup =
      fetchWikimediaExtension "InviteSignup" "2e39d0b766d3c6d82ccf9a530f2f2fea93c2bede"
        "sha256-Q4Pe1kr3aWEK7XpDaD4Mq6t5Rs4/oYUgEc2bOZGMWf0=";
    JsonConfig =
      fetchWikimediaExtension "JsonConfig" "d6216d7eff1ae7a546e81b086625ce5674244ed0"
        "sha256-uDdO3mwRiGrwNX7Kh7IpAV1SPIxzs7wHyugXh7yJwm0=";
    MultimediaViewer =
      fetchWikimediaExtension "MultimediaViewer" "bedf4c47d7796b1f5475194cd96cf5fd4e3a73c3"
        "sha256-KtO+D0DFiZFuLEn5uMbQjOtfQlyf9MzkNiy3cHEk1T4=";
    mwGoogleSheet =
      fetchGitHubArchive "marcidy/mwGoogleSheet" "c1d447be069cfad830bd493bd0e15b1be528d2de"
        "sha256-B0URmW+MAxwXn6pIr4CnQBl+vLqt+81M1lGfMHx7TKs=";
    NBWTF =
      let
        src =
          fetchGitHubArchive "audiodude/nb.wtf" "dfd81cde960a9cc550d1a97db332efb6c6d9578f"
            "sha256-KJ0oZgEDK7M6iSfOFbpc85GmjcJtrNnluBt1zkGDOH8=";
      in
      pkgs.runCommand "NBWTF" { inherit src; } ''
        mkdir -p "$out"
        cp -R "$src/extension/NBWTF/." "$out/"
      '';
    Nuke =
      fetchWikimediaExtension "Nuke" "5d5467046647117fb7fda5890afd54d550842426"
        "sha256-3kHM+2DuItAotagnI0Suhv5vP9fnrmvCYJutxv/QRYY=";
    OATHAuth =
      fetchWikimediaExtension "OATHAuth" "70b5eddad19431a8cda3c33291d80d937614e2a0"
        "sha256-sUdxH9sZjZbZ9xWcItLuvq4vwyu/DdrLvjUBsDiq6Ng=";
    PageImages =
      fetchWikimediaExtension "PageImages" "1c5af7d601ba8da3b6fe63e8d6e355a8a807ca44"
        "sha256-4vVEt3WhPJAxGcqYKViqWt/ls2YKY9lRtsuVyg59SY4=";
    ParserFunctions =
      fetchWikimediaExtension "ParserFunctions" "afca9e971d37af840beb0d18b3cd1bb288cff2da"
        "sha256-OZrCR9EWyUHzIwwOBabO4jlw3M/B9IKHeDD0gy5CHF0=";
    Popups =
      fetchWikimediaExtension "Popups" "077e5d5d736350c317eb0e89d74cb865bec94be5"
        "sha256-2pTf+tlaMv3zc0st8yYMPNRr2lQKO/ZgQCwQeWX4/cY=";
    Renameuser =
      fetchWikimediaExtension "Renameuser" "b0a8544cb1ff45f01190f222d4b2d7c99959fe7f"
        "sha256-39VsqhSuKfOnL/6hwfeFyHsxSJr/VTnJE5BlfCP+2MA=";
    Scribunto =
      fetchWikimediaExtension "Scribunto" "a88e0fd4c54a65e9542bba3287b64605174371e0"
        "sha256-pHS8nTMLb9lMqsvFU7sgWRvMOviW0NU80C26vl5VC7A=";
    TemplateData =
      fetchWikimediaExtension "TemplateData" "15a04ff238648051415d08de0b0eddb41f440762"
        "sha256-eZmD/YViugtgMaCZ+bqyqM6esqIRLwLN2WIflv2E8NM=";
    TextExtracts =
      fetchWikimediaExtension "TextExtracts" "8fc857df757cd105bc79e36f0a4e8ad53ae92921"
        "sha256-L3naN3jkvX4XjunvkKTCoz+CAgLFVzOALZhtaCtGfRE=";
    Thanks =
      fetchWikimediaExtension "Thanks" "2e494787e401eea347f686ccf5ff5576b7671596"
        "sha256-ZvSf8VvdOmvN+3Fol0BLB52m5yRUfMGRzfsBBpgQLA0=";
    VisualEditor =
      fetchWikimediaExtension "VisualEditor" "8d1a70cf06946e0000ab2b6904b80f2c97bd1f16"
        "sha256-i/6Psyqxd5bQYpXEeQMlS9/pvUeidErOaaVK+fAsjpw=";
    WikiEditor =
      fetchWikimediaExtension "WikiEditor" "b191677753cd7639c91b8ae078e8a985eea6c53f"
        "sha256-KWsFRwgDb63kvL5rCgPzsoEYaq4jGfJbnGXxjNTEt7I=";
    QRLite =
      fetchGitHubZipArchive "gesinn-it/QRLite" "caab2f6054d5269a415b135ee66751c2fe429149"
        "sha256-2lDe2gkHVZcUc7O15xqLn8C3NHlNA3ABtZtXnosK8G8=";
    EmbedVideo =
      let
        src = pkgs.fetchzip {
          url = "https://gitlab.com/HydraWiki/extensions/EmbedVideo/-/archive/v2.9.0/EmbedVideo-v2.9.0.zip";
          hash = "sha256-YW/bTJ0lT+obmhj2DStQs5WngonLQhC+3pt2V//V7+A=";
        };
      in
      pkgs.runCommand "EmbedVideo" { inherit src; } ''
        cp -R "$src" "$out"
        chmod -R u+w "$out"
        sed -i "s/\$out->addModules('ext.embedVideo');/\$out->addModules(['ext.embedVideo']);/" "$out/EmbedVideo.hooks.php"
        sed -i "s/\$out->addModuleStyles('ext.embedVideo.styles');/\$out->addModuleStyles(['ext.embedVideo.styles']);/" "$out/EmbedVideo.hooks.php"
      '';
  };

  skins = {
    CologneBlue =
      fetchWikimediaSkin "CologneBlue" "0aa60e3dccae25d9c03e7e8dd1b42ff396fafb73"
        "sha256-Q5B7EWmZlKWSnHg/Rsl6pdO/lto5OOmSnO04z8//8cM=";
    MinervaNeue =
      fetchWikimediaSkin "MinervaNeue" "91b152c07c0948c08a54c3b4ef80875ab6adccae"
        "sha256-CMTXnVGeRDXzIaisQ4R5CvpEjKRkUurBXGe88BhgsDc=";
    Modern =
      fetchWikimediaSkin "Modern" "0c8f0c821b5d092c48e401cff61fd43b8a50f7da"
        "sha256-KxUUU8FCgLJOboBthsMPFRp94nzmZAa1dbedhkCxYN0=";
    MonoBook =
      fetchWikimediaSkin "MonoBook" "9ce1530f57ead344fe68187501fcb48c76998e1e"
        "sha256-qCMGTfJn1xS/MWN1UEz7I6fIgTOVWIzNoBI5gr1LDZM=";
    Timeless =
      fetchWikimediaSkin "Timeless" "8b03a05cb01e3ae9fc7e71fdb1ce879c0de00557"
        "sha256-/bpzwEdovd8Lh+JTIBrr+e0vWihc2dtyjNKdVkYCeaM=";
    Vector =
      fetchWikimediaSkin "Vector" "2ef12c5db2f4e224fc93ed5ec833cf3a342f8b79"
        "sha256-hlZNbeDcFlAfhPO1T/A/1EcgIr//S7t7+BsU4GqsrAo=";
  };
}

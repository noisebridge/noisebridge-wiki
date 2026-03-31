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

  fetchGitilesGit =
    path: rev: hash:
    pkgs.fetchgit {
      url = "https://gerrit.wikimedia.org/r/${path}";
      inherit rev hash;
      fetchSubmodules = true;
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
      fetchWikimediaExtension "AdminLinks" "b60e6ac6a9fe54d0bc25719454489aef393d5133"
        "sha256-2uIMdbECmBr6opibZyOwR53ztm7t4ZKY5ZLG7xFwnHc=";
    BetaFeatures =
      fetchWikimediaExtension "BetaFeatures" "2d326bea48f8841820ad1f2af216822628ffa768"
        "sha256-4FrFvq9LiJH7yUxc3FoyoV1EttSX1J9akG7i2J957TI=";
    CategoryTree =
      fetchWikimediaExtension "CategoryTree" "c7c36d4922945f9a9560db32ad8b39c10ad8b8b2"
        "sha256-nl8FiakSZT2apWtWhdG88qc583oSWhfMtp+axT7ks4M=";
    CharInsert =
      fetchWikimediaExtension "CharInsert" "113583ba92ca68495697f8f68544b2c93211188b"
        "sha256-CvFo1FtRRCyY8OdcRj1f69y1Iy70HjpxPU5egLkdrzY=";
    CheckUser =
      fetchWikimediaExtension "CheckUser" "11fbd4a0e78c32dbe83307b9a23bc3215c17c667"
        "sha256-qxsDviTMNEDJyAwFMoD0tOWtrTHJD1pM+8FKi/6uwvM=";
    Cite =
      fetchWikimediaExtension "Cite" "b27b45b577d10f005091995fd66e933f52ee9f27"
        "sha256-A6SlDhyJyiTfRiEPluN8pWFL0VXBuOwgvm2nZa3kB5I=";
    CodeEditor =
      fetchWikimediaExtension "CodeEditor" "b8c861a9a4124bcd4963564c42290bddde39f27c"
        "sha256-324pt4mTpWHeHu0WxPlwNx9cF+tv1S2zVclGdubx61Q=";
    ConfirmAccount =
      fetchWikimediaExtension "ConfirmAccount" "15e760d82b4db84f52e2afd2193098aff5155fda"
        "sha256-25JAfJXgqUzslw3JJf5Z3d+bkI9X4aOGrsPHmJdm7ew=";
    ConfirmEdit =
      fetchWikimediaExtension "ConfirmEdit" "0b3c343085abba38c0ace5ea9416c5ef035729ff"
        "sha256-Q5I1ERTgyvqSa9VlT0twtRpPB02C2H4VUuGUlnc1V6c=";
    Echo =
      fetchWikimediaExtension "Echo" "8edd3eed8bdafff440d32b71d90145d878763bf5"
        "sha256-QE4FbJCmm8/xiH/nUR76slxw+uD9oK1XwhPSXwx1PQQ=";
    Gadgets =
      fetchWikimediaExtension "Gadgets" "e42e4505af1f90bc8793e9c91fe190767088b95a"
        "sha256-MSjvhR3t2YbZCGuUAf49MI45J/x4d4gHI7uxUQJJztE=";
    Graph =
      fetchGitilesGit "mediawiki/extensions/Graph" "bd416299450c4cdd608563ad2faebb43cde9a3db"
        "sha256-VgOA0VROh/Vtnb54+BgApVpsckcCalN6wh+Fc69zQII=";
    ImageMap =
      fetchWikimediaExtension "ImageMap" "2759c8865e7ee8007c9174ed0c0640d0f9e12109"
        "sha256-k11rlLzbMWU1W0d7NtudWe0VlILxsByqEsqKb+n1hsE=";
    InputBox =
      fetchWikimediaExtension "InputBox" "063fcbb736d32f62b50a6ff14d8d76c90f4c3ff2"
        "sha256-2Gbwf4P3IWeNFZ8Dp+Zkbs1BiI7xcv6huw8vGrfYENU=";
    Interwiki =
      fetchWikimediaExtension "Interwiki" "04b8c6c116f35f4cf6bf2c39ebf7930c75057b3b"
        "sha256-qWwXLsuPAJJQ639YD0WRbeb3yGghOgNjR5PIinpuAYk=";
    InviteSignup =
      fetchWikimediaExtension "InviteSignup" "de58cc6acd6a37b5dd75d1ff0eed455014177978"
        "sha256-seS8OTvgvVWUeMufWb10ry0YTncEBP2yLlhl72YNk3Q=";
    JsonConfig =
      fetchWikimediaExtension "JsonConfig" "11138226c0e5afa5662ef9380c6230058ed89f97"
        "sha256-tRhM+J2s43IbaSeMA4aErzqF9cLbHX4vDDJyFu72kuM=";
    MultimediaViewer =
      fetchWikimediaExtension "MultimediaViewer" "f98c21bbfb6c22ef67cac85050d08b111687f458"
        "sha256-eIO34N63EPC5syy42kf4E3RiyaEOlRDNv6aB8ZfXVOU=";
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
      fetchWikimediaExtension "Nuke" "b5a55e04819ccd45799b87f2158d5c2f6b716cf3"
        "sha256-LVznYjS2mWmxlhzvhzFSOqkeyxh4ra04howHvHcekhY=";
    OATHAuth =
      fetchWikimediaExtension "OATHAuth" "a4d7596bef249fdf47138b08402cd239bae6d8a4"
        "sha256-rZPARmUFRuSf1D6ukDv769xY0InumBULlk2eLAfD3/s=";
    PageImages =
      fetchWikimediaExtension "PageImages" "e8619e4b6c12749b523c12268ca3978ad108ef35"
        "sha256-O268wK2Vxyzig3wEX0sNe0C8eK7/yETHqe7YV7a0+Uw=";
    ParserFunctions =
      fetchWikimediaExtension "ParserFunctions" "830f7dce85d4f57018af0c62fdea9d6b25cb33a1"
        "sha256-5TNy9zkgurAkGNFypmJpaILuNtgC09tAP35a0tudwNA=";
    Popups =
      fetchWikimediaExtension "Popups" "95f341e41eac6ca049bf242c0b8ba0ec3d7eb37e"
        "sha256-rsWvigdB0xcWLmUEnAI2dDV0aFISq8IKfxwwR4Bm3aM=";
    Renameuser =
      fetchWikimediaExtension "Renameuser" "877b8ee5a65bf19924bd2d3e96140d6b69f5fcdd"
        "sha256-sxwJj7H//wwQCvCUepRPtGtpKWnSSzieaKyFtOgDqAI=";
    Scribunto =
      fetchWikimediaExtension "Scribunto" "325e44b03395705ea8d1de6b32f9f7be6f12d717"
        "sha256-jHHabuB1mdyav+8JjgJSInuenNfvF+3EWpb5gP5IHjk=";
    TemplateData =
      fetchWikimediaExtension "TemplateData" "2c6c7c1cd735dcc3a53c35dda83c91d4dfc62836"
        "sha256-PR5mzfvzeOGmhYxxJsoewZjdVY4PMm8wZU4VBiVL6os=";
    TextExtracts =
      fetchWikimediaExtension "TextExtracts" "f6f1593834e4a37657238e45938771440e6334d3"
        "sha256-enFr0fBPCUKhK5aXEU+kjxE36xo/1b9Oxvm+U/m6YL0=";
    Thanks =
      fetchWikimediaExtension "Thanks" "e693b7bdb15d909207336c6380df2050c778bab2"
        "sha256-+chI7i2702bv06iVc04/rEt2RPNLPHYvOTNZuJ/08Qw=";
    VisualEditor =
      fetchWikimediaExtension "VisualEditor" "668ed3ab2851ddf758d3a878f98d61aba33707fa"
        "sha256-CLRBDiyTgGLeYAeMBeiE8WPTmAtwzFHi5K1a7AJoTpQ=";
    WikiEditor =
      fetchWikimediaExtension "WikiEditor" "cdda07652cf836f717ec60d889f161ce3cfacdee"
        "sha256-Rl5cEpL45Q4RCgg7kvGX9zQRha5fuPvWtIyj4DIxEHw=";
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
      fetchWikimediaSkin "CologneBlue" "cf36720efd73c28ccac82cd421c3affae311d41c"
        "sha256-kaXoQyldP1BC4spshOYcDfVE2IgRmtPOdVIy+AJaelU=";
    MinervaNeue =
      fetchWikimediaSkin "MinervaNeue" "3aacba1eb30d08432b6f62f79dc3ab970fb5e7c6"
        "sha256-Rb2HG/raj8A5Jmz20/V9NxfFqkbi3bFZ1vjWX8WfnL0=";
    Modern =
      fetchWikimediaSkin "Modern" "dfa6e0d464ba72113f383ab01bb9f847e751b780"
        "sha256-ZnMFMD1gbRndow5bCnxGZG3gKz1ncsHs3OHRokIJtuA=";
    MonoBook =
      fetchWikimediaSkin "MonoBook" "73c5041e5e54830d02571fc01603e7887503c4ef"
        "sha256-+qD7RksLcO9+/e3cdfytRfJHgWjUVl4rxxo3n/UoxaE=";
    Timeless =
      fetchWikimediaSkin "Timeless" "0facc323c9c1c0233fff22006f1a4d8758517e77"
        "sha256-c6pcP/CYqD/tjwKpra28hJR/JW6A6sqe6LSwbVe4Jsw=";
    Vector =
      fetchWikimediaSkin "Vector" "a0465246fe2cccc4787d580f75b37c59462e69b5"
        "sha256-bnsnmM9afaJD3h8nyXxe0XuX0Sz9puret/igvTj1HoA=";
  };
}

{
  description = "Basic MediaWiki primary + replica deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-mediawiki-1_39.url = "github:NixOS/nixpkgs/nixos-23.05";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-mediawiki-1_39,
      agenix,
      deploy-rs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mediawikiLegacyPkgs = nixpkgs-mediawiki-1_39.legacyPackages.${system};
      lib = nixpkgs.lib;

      mediawikiCorePackage = mediawikiLegacyPkgs.mediawiki.overrideAttrs (_: {
        version = "1.39.13";
        src = mediawikiLegacyPkgs.fetchurl {
          url = "https://releases.wikimedia.org/mediawiki/1.39/mediawiki-1.39.13.tar.gz";
          hash = "sha256-u3AMCXkuzgh3GBoXTBaHOJ09/5PIpfOfgbp1Cb3r7NY=";
        };
      });

      siteConfig = rec {
        wikiName = "Noisebridge";
        baseDomain = "wiki.extremist.software";
        sshUser = "jet";
        deploySshUser = "github-actions";
        adminUsers = {
          github-actions = {
            # CI uses a single pinned deploy key rather than a GitHub account key set.
            sshKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOa5REOdpPV8LloMLXb/6JIHkdrTyKieBneDThd+w3KM github-actions deploy"
            ];
          };
          jet = {
            sshKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE40ISu3ydCqfdpb26JYD5cIN0Fu0id/FDS+xjB5zpqu jetthomaspham@gmail.com"
            ];
            githubUsers = [ "jetpham" ];
          };
        };
        primaryHostName = "main-wiki";
        replicaHostName = "replica-wiki";

        domains = {
          primary = baseDomain;
          replica = "replica.${baseDomain}";
          dumps = "dumps.${baseDomain}";
        };

        deploySigningPublicKey = "noisebridge-wiki-deploy-1:j9CAnUOOkOxOdAhkNKqGQ7RtUaZeJA0tOHXqofruuWI=";

        mediawiki = {
          articlePath = "/wiki/$1";
          scriptPath = "";
          uploadPath = "/images";
          uploadsDir = "/srv/mediawiki/images";
          staticAssetsDir = "/srv/mediawiki/img";
          fileCacheDir = "/var/cache/mediawiki";
          emergencyContact = "webmaster@noisebridge.net";
          passwordSender = "do-not-reply@noisebridge.net";
          readOnlyMessage = "This wiki replica is read-only.";
          allowedSkins = [
            "CologneBlue"
            "MonoBook"
            "Vector"
            "MinervaNeue"
            "Modern"
            "Timeless"
          ];
          enabledExtensions = [
            "AdminLinks"
            "BetaFeatures"
            "CategoryTree"
            "CharInsert"
            "CheckUser"
            "Echo"
            "ConfirmAccount"
            "ConfirmEdit"
            "EmbedVideo"
            "Gadgets"
            "Graph"
            "ImageMap"
            "InputBox"
            "Interwiki"
            "InviteSignup"
            "JsonConfig"
            "MultimediaViewer"
            "mwGoogleSheet"
            "NBWTF"
            "Nuke"
            "PageImages"
            "ParserFunctions"
            "Popups"
            "QRLite"
            "Renameuser"
            "Scribunto"
            "Thanks"
            "TextExtracts"
            "VisualEditor"
          ];
          deferredExtensions = [
            "Cite"
            "CodeEditor"
            "OATHAuth"
            "TemplateData"
            "WikiEditor"
          ];
          dumps = {
            publicDomain = siteConfig.domains.dumps;
            publicDir = "/var/www/${siteConfig.domains.dumps}";
            privateDir = "/var/backups/wiki";
            privateKeepDays = 14;
            publicKeepDays = 7;
            onCalendar = "02:00";
          };
        };

        database = {
          name = "noisebridge_mediawiki";
          sourceName = "wiki";
          mediawikiUser = "wiki";
          replicationUser = "repl";
          tablePrefix = "wiki_";
        };

        hosts = {
          primary = {
            nixosName = primaryHostName;
            publicIpv4 = "134.199.221.52";
          };
          replica = {
            nixosName = replicaHostName;
            publicIpv4 = "167.99.174.109";
          };
        };
      };

      mkPublicDomain = role: siteConfig.domains.${if role == "primary" then "primary" else "replica"};

      mkHostMeta =
        role:
        siteConfig.hosts.${role}
        // {
          inherit role;
          publicDomain = mkPublicDomain role;
        };

      mkDeployHost =
        hostModule: hostMeta:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              agenix
              siteConfig
              hostMeta
              mediawikiCorePackage
              ;
          };
          modules = [
            agenix.nixosModules.default
            hostModule
            ./modules/common.nix
            ./modules/admin-users.nix
            ./modules/deploy-ssh.nix
            ./modules/wiki-dumps.nix
          ];
        };

      primaryMeta = mkHostMeta "primary";
      replicaMeta = mkHostMeta "replica";
    in
    {
      nixosConfigurations = {
        main-wiki = mkDeployHost ./hosts/main-wiki.nix primaryMeta;

        replica-wiki = mkDeployHost ./hosts/replica-wiki.nix replicaMeta;
      };

      deploy.nodes = {
        main-wiki = {
          hostname = primaryMeta.publicDomain;
          remoteBuild = false;
          sshUser = siteConfig.deploySshUser;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.main-wiki;
          };
        };

        replica-wiki = {
          hostname = replicaMeta.publicDomain;
          remoteBuild = false;
          sshUser = siteConfig.deploySshUser;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.replica-wiki;
          };
        };
      };

      checks = builtins.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      apps.${system} = {
        check = {
          type = "app";
          program = "${pkgs.writeShellScript "check-noisebridge" ''
            nix build .#checks.${system}.deploy-activate
            nix build .#checks.${system}.deploy-schema
            nix build .#nixosConfigurations.main-wiki.config.system.build.toplevel --print-build-logs
            nix build .#nixosConfigurations.replica-wiki.config.system.build.toplevel --print-build-logs
          ''}";
          meta.description = "Run Noisebridge wiki validation and host builds";
        };

        deploy = {
          type = "app";
          program = "${pkgs.writeShellScript "deploy-noisebridge" ''
            if [ "$#" -lt 1 ] || [ "''${1#-}" != "$1" ]; then
              printf 'Usage: nix run .#deploy -- <ssh-user> [deploy-rs args or target]\n' >&2
              printf 'Example: nix run .#deploy -- github-actions\n' >&2
              printf 'Example: nix run .#deploy -- jet .#main-wiki\n' >&2
              exit 1
            fi

            deploy_user="$1"
            shift

            deploy_signing_key="''${LOCAL_KEY:-''${NOISEBRIDGE_DEPLOY_SIGNING_KEY:-$HOME/.config/noisebridge-wiki/deploy-signing-key}}"
            if [ ! -f "$deploy_signing_key" ]; then
              printf 'Missing deploy signing key: %s\n' "$deploy_signing_key" >&2
              printf 'Expected public key: %s\n' '${siteConfig.deploySigningPublicKey}' >&2
              exit 1
            fi

            main_path=$(nix build '.#deploy.nodes.main-wiki.profiles.system.path' --print-out-paths)
            ${pkgs.nix}/bin/nix store sign --recursive --key-file "$deploy_signing_key" "$main_path"

            replica_path=$(nix build '.#deploy.nodes.replica-wiki.profiles.system.path' --print-out-paths)
            ${pkgs.nix}/bin/nix store sign --recursive --key-file "$deploy_signing_key" "$replica_path"

            if [ "$#" -eq 0 ] || [ "''${1#-}" != "$1" ]; then
              exec ${deploy-rs.packages.${system}.default}/bin/deploy \
                --auto-rollback true \
                --magic-rollback true \
                --skip-checks \
                --ssh-user "$deploy_user" \
                path:.# \
                "$@"
            fi

            exec ${deploy-rs.packages.${system}.default}/bin/deploy \
              --auto-rollback true \
              --magic-rollback true \
              --skip-checks \
              --ssh-user "$deploy_user" \
              "$@"
          ''}";
          meta.description = "Deploy hosts with an explicit SSH user";
        };

        bootstrap-host = {
          type = "app";
          program = "${pkgs.writeShellScript "bootstrap-host" (
            builtins.replaceStrings
              [
                "@ADMIN_USERS_JSON@"
                "@JQ@"
                "@DEPLOY_SIGNING_PUBLIC_KEY@"
              ]
              [
                (builtins.toJSON siteConfig.adminUsers)
                "${pkgs.jq}/bin/jq"
                siteConfig.deploySigningPublicKey
              ]
              (builtins.readFile ./scripts/bootstrap-host.sh)
          )}";
          meta.description = "Convert one or both Ubuntu DigitalOcean hosts into a minimal NixOS bootstrap config with nixos-infect";
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          agenix.packages.${system}.default
          deploy-rs.packages.${system}.default
          mariadb.client
          rsync
          curl
          jq
          age
          openssl
        ];
      };
    };
}

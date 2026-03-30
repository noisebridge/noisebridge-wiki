{
  description = "Basic MediaWiki primary + replica deployment";

  nixConfig = {
    max-jobs = "auto";
    cores = 0;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
      agenix,
      deploy-rs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      siteConfig = rec {
        wikiName = "Noisebridge";
        baseDomain = "extremist.software";
        sshUser = "jet";
        deploySshUser = "github-actions";
        adminUsers = {
          github-actions = {
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOa5REOdpPV8LloMLXb/6JIHkdrTyKieBneDThd+w3KM github-actions deploy"
            ];
          };
          jet = {
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE40ISu3ydCqfdpb26JYD5cIN0Fu0id/FDS+xjB5zpqu jetthomaspham@gmail.com"
            ];
          };
        };
        primaryHostName = "main-wiki";
        replicaHostName = "replica-wiki";

        domains = {
          primary = "${primaryHostName}.${baseDomain}";
          replica = "${replicaHostName}.${baseDomain}";
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
            inherit agenix siteConfig hostMeta;
          };
          modules = [
            agenix.nixosModules.default
            hostModule
            ./modules/common.nix
            ./modules/admin-users.nix
            ./modules/deploy-ssh.nix
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
          hostname = primaryMeta.publicIpv4;
          remoteBuild = false;
          sshUser = siteConfig.deploySshUser;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.main-wiki;
          };
        };

        replica-wiki = {
          hostname = replicaMeta.publicIpv4;
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
        deploy = {
          type = "app";
          program = "${pkgs.writeShellScript "deploy-noisebridge" ''
            deploy_signing_key="''${LOCAL_KEY:-''${NOISEBRIDGE_DEPLOY_SIGNING_KEY:-$HOME/.config/noisebridge-wiki/deploy-signing-key}}"
            if [ ! -f "$deploy_signing_key" ]; then
              printf 'Missing deploy signing key: %s\n' "$deploy_signing_key" >&2
              printf 'Expected public key: %s\n' '${siteConfig.deploySigningPublicKey}' >&2
              exit 1
            fi

            nix build .#checks.${system}.deploy-activate --accept-flake-config
            nix build .#checks.${system}.deploy-schema --accept-flake-config

            main_path=$(nix build '.#deploy.nodes.main-wiki.profiles.system.path' --accept-flake-config --print-out-paths)
            ${pkgs.nix}/bin/nix store sign --recursive --key-file "$deploy_signing_key" "$main_path"

            replica_path=$(nix build '.#deploy.nodes.replica-wiki.profiles.system.path' --accept-flake-config --print-out-paths)
            ${pkgs.nix}/bin/nix store sign --recursive --key-file "$deploy_signing_key" "$replica_path"

            if [ "$#" -eq 0 ] || [ "''${1#-}" != "$1" ]; then
              exec ${deploy-rs.packages.${system}.default}/bin/deploy \
                --auto-rollback true \
                --magic-rollback true \
                --skip-checks \
                path:.# \
                "$@"
            fi

            exec ${deploy-rs.packages.${system}.default}/bin/deploy \
              --auto-rollback true \
              --magic-rollback true \
              --skip-checks \
              "$@"
          ''}";
          meta.description = "Deploy all Noisebridge wiki hosts by default";
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

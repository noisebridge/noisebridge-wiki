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
        adminUsers = {
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
        };

        database = {
          name = "noisebridge_mediawiki";
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
          sshUser = siteConfig.sshUser;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.main-wiki;
          };
        };

        replica-wiki = {
          hostname = replicaMeta.publicIpv4;
          remoteBuild = false;
          sshUser = siteConfig.sshUser;
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
            if [ "$#" -eq 0 ] || [ "''${1#-}" != "$1" ]; then
              exec ${deploy-rs.packages.${system}.default}/bin/deploy \
                --auto-rollback true \
                --magic-rollback true \
                path:.# \
                "$@"
            fi

            exec ${deploy-rs.packages.${system}.default}/bin/deploy \
              --auto-rollback true \
              --magic-rollback true \
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
              ]
              [
                (builtins.toJSON siteConfig.adminUsers)
                "${pkgs.jq}/bin/jq"
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

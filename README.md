# Noisebridge Wiki

This repository manages the Nix-based infrastructure for the Noisebridge MediaWiki deployment.

## Overview

The flake currently deploys a two-host setup:

- [`wiki.extremist.software`](https://wiki.extremist.software): primary wiki, writable MediaWiki, MariaDB primary, Caddy, PHP-FPM
- [`replica.wiki.extremist.software`](https://replica.wiki.extremist.software): read-only wiki, MariaDB replica, Caddy, PHP-FPM

Change `siteConfig.baseDomain` in `flake.nix` to move the public wiki hostnames together.

## Repository Layout

- `flake.nix`: top-level flake, deploy definitions, checks, and app entrypoints
- `hosts/main-wiki.nix`: primary host configuration
- `hosts/replica-wiki.nix`: replica host configuration
- `modules/mediawiki-packages.nix`: pinned MediaWiki extensions and skins
- `scripts/`: migration, export/import, and bootstrap helpers
- `secrets/`: agenix-encrypted secrets and host recipients

## Common Commands

Validate the repo and build both host configurations:

```sh
nix run .#check
```

Deploy both hosts as a specific SSH user:

```sh
nix run .#deploy -- jet
```

Deploy a single host:

```sh
nix run .#deploy -- jet .#main-wiki
nix run .#deploy -- jet .#replica-wiki
```

CI deploys with:

```sh
nix run .#deploy -- github-actions
```

Bootstrap fresh Ubuntu hosts into NixOS:

```sh
nix run .#bootstrap-host -- --admin <name> <main-wiki|replica-wiki> <target-host> [ssh-identity-file]
nix run .#bootstrap-host -- --admin <name> <main-target-host> <replica-target-host> [ssh-identity-file]
```

## Deployment Notes

- The deploy app always requires an explicit SSH user.
- `jet` is the normal interactive admin deploy user.
- `github-actions` is the CI deploy user.
- Deploys use `deploy-rs`.
- `nix run .#check` is the intended pre-deploy validation step.
- Deploys require a local signing key at `$LOCAL_KEY`, `$NOISEBRIDGE_DEPLOY_SIGNING_KEY`, or `$HOME/.config/noisebridge-wiki/deploy-signing-key`.
- Admin SSH users live in `siteConfig.adminUsers` in `flake.nix`.
- Each admin user can set `sshKeys = [ ... ]`, `githubUsers = [ ... ]`, or both.
- Every GitHub username in `githubUsers` contributes all keys from `https://github.com/<user>.keys` during activation.
- GitHub-backed keys update only when a deploy runs. After deploy, removed GitHub keys stop working and newly added ones start working.

Example:

```nix
adminUsers = {
  alice = {
    sshKeys = [
      "ssh-ed25519 AAAA... alice@laptop"
    ];
    githubUsers = [ "alice" ];
  };

  bob = {
    githubUsers = [ "bob" ];
  };
};
```

## MediaWiki Notes

- MediaWiki core is pinned to `1.39.13`.
- Wikimedia extensions and skins are pinned in `modules/mediawiki-packages.nix`.
- Uploaded files live at `/srv/mediawiki/images`.
- Local static assets live at `/srv/mediawiki/img`.
- Nightly dumps run at `02:00` local time on `replica-wiki`: a private full-history dump with uploads/files for backup and a public current-only dump for bots.
- Public dumps are served from `dumps.extremist.software` out of `/var/www/dumps.extremist.software`.

## Migration Scripts

Useful helpers in `scripts/`:

- `scripts/migrate-all.sh`: full content migration flow
- `scripts/import-db-to-main.sh`: import the database into primary and reseed replica
- `scripts/import-files-to-main.sh`: copy files into primary
- `scripts/export-prod-db.sh`: export the current production database
- `scripts/export-prod-files.sh`: export the current production files
- `scripts/export-and-import-db.sh`: export and import the database in one step
- `scripts/export-and-import-files.sh`: export and import files in one step
- `scripts/bootstrap-host.sh`: bootstrap one or both hosts from Ubuntu to NixOS

## Secrets

- `agenix` manages runtime secrets.
- Encrypted secret definitions live under `secrets/shared/`.
- Host age recipients live under `secrets/hosts/`.
- Recipient wiring lives in `secrets/secrets.nix`.
- Hosts decrypt secrets using their local age identity.

To add a new person for secret decryption:

1. add their age public key to `adminKeys` in `secrets/secrets.nix`
2. enter the dev shell with `nix develop` so `agenix` is available (or install agenix any other way)
3. run `agenix -r` from the repo root to rekey all secrets using `./secrets.nix`

Example `adminKeys` entry:

```nix
adminKeys = [
  # Example Person
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFakeKeyForExampleOnlyDontUseThis"
];
```

Changing `secrets/secrets.nix` updates the intended recipient list, but the new person cannot actually decrypt anything until `agenix -r` has re-encrypted the existing `.age` files.

## Workflow

Typical admin flow:

1. Edit the Nix configuration.
2. Run `nix run .#check`.
3. Deploy with `nix run .#deploy -- <user>`.
4. Verify the primary and replica hosts.

When making repo changes, use `jj` for commits.

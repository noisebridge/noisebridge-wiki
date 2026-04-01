# Noisebridge Wiki

This repo manages the Noisebridge wiki infrastructure.

It currently deploys a two-host MediaWiki setup:

- `main-wiki.extremist.software`: primary wiki, writable MediaWiki, MariaDB primary, Caddy, PHP-FPM
- `replica-wiki.extremist.software`: read-only wiki, MariaDB replica, Caddy, PHP-FPM
- `wiki.extremist.software`: primary wiki, writable MediaWiki, MariaDB primary, Caddy, PHP-FPM
- `replica.wiki.extremist.software`: read-only wiki, MariaDB replica, Caddy, PHP-FPM

Set `siteConfig.baseDomain` in `flake.nix` to move the whole public wiki hostname tree.

## Repo Layout

- `flake.nix`: top-level Nix flake, deploy definitions, checks, app entrypoints
- `hosts/main-wiki.nix`: primary host configuration
- `hosts/replica-wiki.nix`: replica host configuration
- `modules/mediawiki-packages.nix`: pinned MediaWiki extensions and skins
- `scripts/`: migration and maintenance helpers
- `secrets/`: agenix-encrypted secrets and host recipients

## Common Commands

Check the repo:

```sh
nix run .#check
```

Deploy both hosts:

```sh
nix run .#deploy -- jet
```

Deploy one host:

```sh
nix run .#deploy -- jet .#main-wiki
nix run .#deploy -- jet .#replica-wiki
```

CI deploys with:

```sh
nix run .#deploy -- github-actions
```

Bootstrap a fresh Ubuntu host into NixOS:

```sh
nix run .#bootstrap-host -- --admin <name> <main-wiki|replica-wiki> <target-host> [ssh-identity-file]
nix run .#bootstrap-host -- --admin <name> <main-target-host> <replica-target-host> [ssh-identity-file]
```

## Deployment Notes

- The deploy app requires an explicit SSH user.
- `github-actions` is the CI deploy user.
- Deploys are done with `deploy-rs`.
- `nix run .#check` is the pre-deploy validation entrypoint.

Add an admin by creating another entry in `siteConfig.adminUsers` in `flake.nix`:

```nix
examplePerson = {
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFakeKeyForExampleOnlyDontUseThis"
  ];
};
```

## MediaWiki Notes

- MediaWiki core is pinned to `1.39.13`.
- Wikimedia extensions and skins are pinned in `modules/mediawiki-packages.nix`.
- Uploads live at `/srv/mediawiki/images`.
- Local static assets live at `/srv/mediawiki/img`.

## Migration Scripts

Useful scripts in `scripts/`:

- `scripts/migrate-all.sh`: full content migration flow
- `scripts/import-db-to-main.sh`: import DB into primary and reseed replica
- `scripts/import-files-to-main.sh`: copy files into primary
- `scripts/export-prod-db.sh`: export DB from the current production source
- `scripts/export-prod-files.sh`: export files from the current production source

## Secrets

- agenix manages runtime secrets
- encrypted secret definitions live under `secrets/`
- host recipients live under `secrets/hosts/`
- hosts decrypt using their local age identity

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

Typical admin workflow:

1. edit Nix config
2. run `nix run .#check`
3. deploy with `nix run .#deploy -- <user>`
4. verify both wiki hosts

When making repo changes, use `jj` for commits.

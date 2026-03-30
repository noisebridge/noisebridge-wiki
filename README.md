# Noisebridge Wiki *2.0 Prototype*

This repo manages the Noisebridge wiki. It is currently for the Noisebridge Wiki 2.0 Prototype that is planned to eventually replace the current Noisebridge wiki infrastructure.

## Development Hosts

- primary wiki: `main-wiki.extremist.software`
- read-only replica: `replica-wiki.extremist.software`
- deployment/admin SSH user: `jet` *this is hoped to expand soon!*

A note here, once this project is underway, CI/CD should only allow changes to come through reviewed PRs into the main branch. These changes would then be built and deployed from an automated Github action (could be forgejo actions in the future)

The current repo is the deployment foundation for a two-machine MediaWiki stack:

- primary host: MediaWiki, MariaDB primary, Caddy, agenix-managed secrets
- replica host: MediaWiki, MariaDB read-only replica, Caddy, agenix-managed secrets

We haven't fully implemented all the features, but the remaining work is tracked here so this README can act as the main working checklist.

## Implementation Checklist

### Core rollout

- [ ] Finish `hosts/main-wiki.nix` with MediaWiki, MariaDB primary, Caddy, and agenix-managed secrets
- [ ] Finish `hosts/replica-wiki.nix` with MediaWiki, MariaDB replica, Caddy, and agenix-managed secrets
- [ ] Make the flake configuration fully express hostnames, domains, shared secrets, and host-only secrets
- [ ] Wire all required agenix secrets into services on both hosts
- [ ] Keep both machine closures building cleanly from the flake
- [ ] Keep `deploy-rs` as the standard deployment path for both machines

### Database and replication

- [ ] Create the MediaWiki MariaDB database and application user on the primary
- [ ] Configure MariaDB replication user and secure replication credentials
- [ ] Configure the replica host as a real read-only MariaDB replica
- [ ] Verify replication from primary to replica under normal wiki writes
- [ ] Document promotion and rebuild expectations for the replica

### MediaWiki application

- [ ] Choose and pin the exact MediaWiki version for the new stack
- [ ] Recreate the current wiki configuration from `LocalSettings.php` in a maintainable Nix-managed form
- [ ] Configure uploads, logo, favicon, and local asset paths
- [ ] Reinstall and validate required extensions
- [ ] Reinstall and validate any non-default skins
- [ ] Recreate job queue or maintenance task execution needed by the wiki
- [ ] Confirm the primary wiki is writable
- [ ] Confirm the replica wiki is publicly readable and actually read-only

### Web serving and TLS

- [ ] Configure Caddy virtual hosts for `main-wiki.extremist.software`
- [ ] Configure Caddy virtual hosts for `replica-wiki.extremist.software`
- [ ] Configure TLS and renewal behavior for both public hosts
- [ ] Recreate any needed redirects, asset routes, and static file handling
- [ ] Verify PHP-FPM and web serving behavior under the chosen runtime

### Migration and cutover

- [ ] Dump the current MediaWiki database
- [ ] Verify the actual table prefix used in production
- [ ] Copy uploaded files from `/srv/mediawiki/noisebridge.net/images/`
- [ ] Copy local static assets from `/srv/mediawiki/noisebridge.net/img/`
- [ ] Copy and review the current `LocalSettings.php`
- [ ] Inventory current secrets including DB credentials, MediaWiki secret keys, upgrade key, and ReCaptcha keys
- [ ] Inventory the exact live MediaWiki version, extensions, skins, and Composer-managed dependencies
- [ ] Inventory current Caddy and PHP-FPM runtime configuration
- [ ] Inventory cron or systemd jobs related to MediaWiki maintenance, backups, or queues
- [ ] Measure current database and upload sizes for migration planning
- [ ] Produce rollback notes for the final cutover
- [ ] Import production data into the new primary host
- [ ] Verify the replica catches up from the imported primary state
- [ ] Smoke test reading, editing, login, uploads, search, history, and diff behavior before cutover

### CI/CD and repository workflow

- [ ] Require reviewed PRs before merge to `main`
- [ ] Block direct pushes to `main`
- [ ] Keep `nix flake check` required in CI
- [ ] Keep both host builds required in CI
- [ ] Keep automatic deploys on pushes to `main`
- [ ] Add post-deploy smoke checks if needed
- [ ] Optionally move from GitHub Actions to Forgejo Actions later

### Security and access policy

- [ ] Explicitly define anonymous user permissions in MediaWiki
- [ ] Keep account creation invite-only
- [ ] Allow read, search, history, and diff access where desired
- [ ] Restrict broader special-page use for anonymous traffic
- [ ] Review SSH/admin access model beyond the initial `jet` user

## Future Features Checklist

### Edge and public access

- [ ] Use the final apex domain for the primary wiki
- [ ] Serve the final replica from `replica.<domain>`
- [ ] Support a direct-to-origin non-Cloudflare deployment mode
- [ ] Add a separate Cloudflare-proxied deployment mode later

### Performance and abuse controls

- [ ] Add aggressive anonymous rate limiting in Caddy
- [ ] Add cache policy that favors anonymous page views
- [ ] Reduce or bypass caching for logged-in and dynamic traffic
- [ ] Preserve good behavior for logged-in editors while limiting abuse
- [ ] Add stronger service and access logging for tuning

### Database evolution

- [ ] Revisit the long-term database backend after the baseline is stable
- [ ] Evaluate migration away from MariaDB if a better fit emerges

### Observability

- [ ] Add public read-only Grafana
- [ ] Add a public status page
- [ ] Add email alerts
- [ ] Add Discord webhook alerts
- [ ] Add more detailed dashboards

### Backups and exports

- [ ] Add encrypted client-side backups to Backblaze B2
- [ ] Define a retention policy
- [ ] Write a restore runbook
- [ ] Support volunteer-hosted backup targets later
- [ ] Provide a scraper-friendly export API instead of forcing heavy live-site scraping
- [ ] Publish a sanitized public SQL subset rather than a raw production dump
- [ ] Generate daily export snapshots
- [ ] Host downloads away from the primary, ideally from the replica side
- [ ] Publish stable JSON metadata for latest export, export history, checksums, and download URLs
- [ ] Add additional public export formats beyond SQL subset dumps

### Tor and alternative access

- [ ] Add a stable onion service for the primary host
- [ ] Add a stable onion service for the replica host
- [ ] Manage onion private keys with agenix so addresses survive rebuilds

### Longer-term operations

- [ ] Write a formal failover and promotion runbook
- [ ] Add stronger deployment protections
- [ ] Add a scheduled flake lock update workflow or an admin-run update script with PR review before merge

## Commands

Bootstrap a brand new Ubuntu 22.04 DigitalOcean VPS into NixOS:

```sh
nix run .#bootstrap-host -- --admin <name> <main-wiki|replica-wiki> <target-host> [ssh-identity-file]
nix run .#bootstrap-host -- --admin <name> <main-target-host> <replica-target-host> [ssh-identity-file]
```

Example:

```sh
nix run .#bootstrap-host -- --admin jet main-wiki root@203.0.113.10 ~/.ssh/do-bootstrap
nix run .#bootstrap-host -- --admin jet root@203.0.113.10 root@203.0.113.11 ~/.ssh/do-bootstrap
```

`--admin <name>` is required. The admin must exist in `siteConfig.adminUsers` in `flake.nix`.

What bootstrap does:

- copies a first-boot module to the host
- runs `nixos-infect` on the Ubuntu VPS
- converts the machine to NixOS with the requested admin user
- disables direct root SSH
- fixes the known bad IPv6 routes generated by `nixos-infect`
- verifies that the requested admin login and `sudo` work and that the host reaches `running`

What bootstrap is not:

- it is not the normal long-term deploy path
- it is not the full application rollout
- it is only the one-off Ubuntu-to-NixOS installer step

> This is made to only be run once and to potentially prop up new servers if needed

Deploy all already-bootstrapped hosts:

```sh
nix run .#deploy
```

Deploy one host only:

```sh
nix run .#deploy -- .#main-wiki
nix run .#deploy -- .#replica-wiki
```

Check the flake:

```sh
nix flake check 'path:.'
```

## Secret Model

- admin keys stay in `secrets/secrets.nix`
- host recipients live in `secrets/hosts/*.age.pub`
- host private age keys stay local in `.bootstrap/` and are gitignored
- hosts decrypt agenix secrets with `/var/lib/agenix/host.age`
- host SSH keys are separate and can rotate without breaking agenix

## Normal Lifecycle

1. Create a raw VPS.
2. Run `nix run .#bootstrap-host -- ...` from the repo root on an admin laptop.
3. The machine installs NixOS and comes up over public SSH.
4. Future configuration changes would be made through CI/CD.

#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <dump-dir> [images|img|all]" >&2
  exit 1
fi

dump_dir="$1"
mode="${2:-all}"
main_ssh_host="${MAIN_SSH_HOST:-jet@main-wiki.extremist.software}"
remote_mediawiki_dir="${REMOTE_MEDIAWIKI_DIR:-/srv/mediawiki}"
rsync_base=(rsync -aH --info=progress2 --rsync-path="sudo rsync")

if [ ! -d "$dump_dir" ]; then
  echo "Dump directory not found: $dump_dir" >&2
  exit 1
fi

copy_images=false
copy_img=false
case "$mode" in
  images) copy_images=true ;;
  img) copy_img=true ;;
  all) copy_images=true; copy_img=true ;;
  *)
    echo "Usage: $0 <dump-dir> [images|img|all]" >&2
    exit 1
    ;;
esac

ssh "$main_ssh_host" "sudo mkdir -p '${remote_mediawiki_dir}/images' '${remote_mediawiki_dir}/img' /var/lib/noisebridge-migration" 

if $copy_images && [ -d "$dump_dir/images" ]; then
  echo "Importing images/ to ${main_ssh_host}" >&2
  "${rsync_base[@]}" "$dump_dir/images/" "${main_ssh_host}:${remote_mediawiki_dir}/images/"
  ssh "$main_ssh_host" "sudo chown -R mediawiki:mediawiki '${remote_mediawiki_dir}/images'"
fi

if $copy_img && [ -d "$dump_dir/img" ]; then
  echo "Importing img/ to ${main_ssh_host}" >&2
  "${rsync_base[@]}" "$dump_dir/img/" "${main_ssh_host}:${remote_mediawiki_dir}/img/"
  ssh "$main_ssh_host" "sudo chown -R mediawiki:mediawiki '${remote_mediawiki_dir}/img'"
fi

if [ -f "$dump_dir/LocalSettings.php" ]; then
  echo "Copying production LocalSettings.php for reference" >&2
  rsync -a "$dump_dir/LocalSettings.php" "${main_ssh_host}:/tmp/prod-LocalSettings.php"
  ssh "$main_ssh_host" "sudo mv /tmp/prod-LocalSettings.php /var/lib/noisebridge-migration/LocalSettings.php.prod && sudo chmod 600 /var/lib/noisebridge-migration/LocalSettings.php.prod"
fi

if [ -f "$dump_dir/extensions.txt" ]; then
  echo "Copying extension inventory for reference" >&2
  rsync -a "$dump_dir/extensions.txt" "${main_ssh_host}:/tmp/prod-extensions.txt"
  ssh "$main_ssh_host" "sudo mv /tmp/prod-extensions.txt /var/lib/noisebridge-migration/extensions.txt && sudo chmod 644 /var/lib/noisebridge-migration/extensions.txt"
fi

echo "Imported file dump ${dump_dir} to ${main_ssh_host}" >&2

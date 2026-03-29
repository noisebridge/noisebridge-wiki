#!/usr/bin/env bash
set -euo pipefail

source_ssh_host="${SOURCE_SSH_HOST:-jetpham@m3.noisebridge.net}"
source_localsettings_path="${SOURCE_LOCALSETTINGS_PATH:-/srv/mediawiki/noisebridge.net/LocalSettings.php}"
dump_dir="${DUMP_DIR:-$(pwd)/dump}"
timestamp="${TIMESTAMP:-$(date -u +%Y%m%d-%H%M%S)}"
output_path="${dump_dir}/mediawiki-db-${timestamp}.sql.zst"

mkdir -p "$dump_dir"

if [ -n "${SOURCE_DB_HOST:-}" ] && [ -n "${SOURCE_DB_NAME:-}" ] && [ -n "${SOURCE_DB_USER:-}" ] && [ -n "${SOURCE_DB_PASS:-}" ]; then
  db_host="$SOURCE_DB_HOST"
  db_name="$SOURCE_DB_NAME"
  db_user="$SOURCE_DB_USER"
  db_pass="$SOURCE_DB_PASS"
else
  php_extract_code=$(cat <<'EOF'
$text = file_get_contents($argv[1]);
foreach (["DBserver", "DBname", "DBuser", "DBpassword"] as $key) {
  $pattern = '/\\$wg' . $key . '\\s*=\\s*["\']([^"\']*)["\'];/';
  if (!preg_match_all($pattern, $text, $matches) || count($matches[1]) === 0) {
    fwrite(STDERR, "Missing \$wg" . $key . " in LocalSettings.php\n");
    exit(1);
  }
  echo end($matches[1]), "\n";
}
EOF
)
  readarray -t db_fields < <(ssh "$source_ssh_host" "php -r $(printf '%q' "$php_extract_code") $(printf '%q' "$source_localsettings_path")")
  db_host="${db_fields[0]}"
  db_name="${db_fields[1]}"
  db_user="${db_fields[2]}"
  db_pass="${db_fields[3]}"
fi

echo "Exporting ${db_name} from ${source_ssh_host} to ${output_path}" >&2

ssh "$source_ssh_host" \
  "dump_bin=\$(command -v mariadb-dump || command -v mysqldump); \"\$dump_bin\" --host='${db_host}' --user='${db_user}' --password='${db_pass}' --single-transaction --quick --routines --triggers --hex-blob --no-tablespaces --default-character-set=utf8mb4 '${db_name}'" \
  | zstd -T0 -19 -o "$output_path"

echo "$output_path"

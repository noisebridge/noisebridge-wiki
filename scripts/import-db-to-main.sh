#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <dump.sql|dump.sql.gz|dump.sql.zst>" >&2
  exit 1
fi

dump_path="$1"
main_ssh_host="${MAIN_SSH_HOST:-jet@wiki.extremist.software}"
replica_ssh_host="${REPLICA_SSH_HOST:-jet@replica.wiki.extremist.software}"
main_wiki_url="${MAIN_WIKI_URL:-https://wiki.extremist.software}"
replica_wiki_url="${REPLICA_WIKI_URL:-https://replica.wiki.extremist.software}"
main_db_host="${MAIN_DB_HOST:-${main_ssh_host#*@}}"
target_db_name="${TARGET_DB_NAME:-noisebridge_mediawiki}"

if [ ! -f "$dump_path" ]; then
  echo "Dump not found: $dump_path" >&2
  exit 1
fi

case "$dump_path" in
  *.sql) decompressor=(cat "$dump_path") ;;
  *.sql.gz) decompressor=(gzip -dc "$dump_path") ;;
  *.sql.zst|*.zst) decompressor=(zstd -dc "$dump_path") ;;
  *)
    echo "Unsupported dump format: $dump_path" >&2
    exit 1
    ;;
esac

echo "Resetting primary database ${target_db_name} on ${main_ssh_host}" >&2
ssh "$main_ssh_host" "sudo mariadb -e \"DROP DATABASE IF EXISTS ${target_db_name}; CREATE DATABASE ${target_db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""

echo "Importing ${dump_path} into primary" >&2
"${decompressor[@]}" | ssh "$main_ssh_host" "sudo mariadb '${target_db_name}'"

echo "Running MediaWiki database setup and update on primary" >&2
ssh "$main_ssh_host" "sudo systemctl start mediawiki-db-setup mediawiki-init && sleep 5 && sudo systemctl --no-pager --full status mediawiki-db-setup mediawiki-init"

echo "Checking primary wiki page" >&2
curl -fsSL -o /dev/null -w '%{http_code}\n' "${main_wiki_url}/wiki/Main_Page" | grep -qx '200'

echo "Resetting replica database ${target_db_name}" >&2
ssh "$replica_ssh_host" "sudo mariadb -e \"STOP SLAVE; RESET SLAVE ALL; DROP DATABASE IF EXISTS ${target_db_name}; CREATE DATABASE ${target_db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""

echo "Seeding replica from primary" >&2
ssh "$main_ssh_host" "sudo mariadb-dump --single-transaction --master-data=2 '${target_db_name}'" | ssh "$replica_ssh_host" "sudo mariadb '${target_db_name}'"

echo "Restarting replica setup and replication" >&2
master_status="$(ssh "$main_ssh_host" "sudo mariadb --batch --skip-column-names -e \"SHOW MASTER STATUS\"")"
set -- $master_status
master_log_file="$1"
master_log_pos="$2"
replication_password="$(ssh "$replica_ssh_host" "sudo tr -d '\n' < /run/agenix/mysql-replication")"
replication_password_sql=${replication_password//\'/\'\'}
ssh "$main_ssh_host" "sudo mariadb-admin flush-hosts"
ssh "$replica_ssh_host" "sudo systemctl start mediawiki-db-setup && sudo mariadb -e \"STOP SLAVE; RESET SLAVE ALL; CHANGE MASTER TO MASTER_HOST='${main_db_host}', MASTER_USER='repl', MASTER_PASSWORD='${replication_password_sql}', MASTER_PORT=3306, MASTER_LOG_FILE='${master_log_file}', MASTER_LOG_POS=${master_log_pos}, MASTER_CONNECT_RETRY=10; START SLAVE;\" && sleep 5 && sudo mariadb -e \"SHOW SLAVE STATUS\\G\" | grep -E 'Master_Host|Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_IO_Error|Last_SQL_Error'"

echo "Checking replica wiki page" >&2
curl -fsSL -o /dev/null -w '%{http_code}\n' "${replica_wiki_url}/wiki/Main_Page" | grep -qx '200'

echo "Imported ${dump_path} into ${main_ssh_host} and reseeded ${replica_ssh_host}" >&2

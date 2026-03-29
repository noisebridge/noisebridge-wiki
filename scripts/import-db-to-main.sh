#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <dump.sql|dump.sql.gz|dump.sql.zst>" >&2
  exit 1
fi

dump_path="$1"
main_ssh_host="${MAIN_SSH_HOST:-jet@main-wiki.extremist.software}"
replica_ssh_host="${REPLICA_SSH_HOST:-jet@replica-wiki.extremist.software}"
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
curl -fsS -o /dev/null -w '%{http_code}\n' https://main-wiki.extremist.software/wiki/Main_Page | grep -qx '200'

echo "Resetting replica database ${target_db_name}" >&2
ssh "$replica_ssh_host" "sudo mariadb -e \"STOP SLAVE; RESET SLAVE ALL; DROP DATABASE IF EXISTS ${target_db_name}; CREATE DATABASE ${target_db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""

echo "Seeding replica from primary" >&2
ssh "$main_ssh_host" "sudo mariadb-dump --single-transaction --master-data=2 '${target_db_name}'" | ssh "$replica_ssh_host" "sudo mariadb '${target_db_name}'"

echo "Restarting replica setup and replication" >&2
ssh "$replica_ssh_host" "sudo systemctl start mediawiki-db-setup mysql-replication-replica && sleep 5 && sudo mariadb -e \"SHOW SLAVE STATUS\\G\" | grep -E 'Master_Host|Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_IO_Error|Last_SQL_Error'"

echo "Checking replica wiki page" >&2
curl -fsS -o /dev/null -w '%{http_code}\n' https://replica-wiki.extremist.software/wiki/Main_Page | grep -qx '200'

echo "Imported ${dump_path} into ${main_ssh_host} and reseeded ${replica_ssh_host}" >&2

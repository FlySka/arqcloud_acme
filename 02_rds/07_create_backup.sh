mkdir -p backups

pg_dump "postgresql://acmeadmin:AcmePass123!@$DB_HOST:$DB_PORT/acme" \
  > backups/acme_backup_$(date +%F_%H%M).sql
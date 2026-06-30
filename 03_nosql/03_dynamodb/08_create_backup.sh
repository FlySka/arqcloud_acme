mkdir -p backups

aws dynamodb scan \
  --table-name TicketsSoporte \
  --endpoint-url http://localhost:4566 \
  --output json > backups/tickets_backup_$(date +%F_%H%M).json

echo "Backup generado en backups/"

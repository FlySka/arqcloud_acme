export DB_HOST=localhost

export DB_PORT=$(aws rds describe-db-instances \
  --query "DBInstances[?DBInstanceIdentifier=='acme-postgres']|[0].Endpoint.Port" \
  --output text)

echo $DB_HOST
echo $DB_PORT
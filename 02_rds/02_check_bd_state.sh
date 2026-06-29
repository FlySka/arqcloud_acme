aws rds describe-db-instances \
  --query "DBInstances[?DBInstanceIdentifier=='acme-postgres']|[0].{ID:DBInstanceIdentifier,Estado:DBInstanceStatus,Motor:Engine,MultiAZ:MultiAZ,Backup:BackupRetentionPeriod,Endpoint:Endpoint.Address,Puerto:Endpoint.Port}" \
  --output table
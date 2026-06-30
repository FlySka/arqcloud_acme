aws dynamodb describe-table \
  --table-name TicketsSoporte \
  --query "Table.{Nombre:TableName,Estado:TableStatus,Indices:GlobalSecondaryIndexes[*].IndexName}" \
  --output table \
  --endpoint-url http://localhost:4566

aws dynamodb query \
  --table-name TicketsSoporte \
  --index-name tecnico-index \
  --key-condition-expression "tecnico = :t" \
  --expression-attribute-values '{ ":t": {"S": "Carlos Perez"} }' \
  --endpoint-url http://localhost:4566

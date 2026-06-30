aws dynamodb query \
  --table-name TicketsSoporte \
  --index-name estado-index \
  --key-condition-expression "estado = :e" \
  --expression-attribute-values '{ ":e": {"S": "Abierto"} }' \
  --endpoint-url http://localhost:4566

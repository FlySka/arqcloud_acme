aws dynamodb query \
  --table-name TicketsSoporte \
  --index-name prioridad-index \
  --key-condition-expression "prioridad = :p" \
  --expression-attribute-values '{ ":p": {"S": "Critica"} }' \
  --endpoint-url http://localhost:4566

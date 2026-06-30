aws dynamodb create-table \
  --table-name TicketsSoporte \
  --attribute-definitions \
    AttributeName=ticketId,AttributeType=S \
    AttributeName=estado,AttributeType=S \
    AttributeName=tecnico,AttributeType=S \
    AttributeName=prioridad,AttributeType=S \
  --key-schema AttributeName=ticketId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes file://gsi.json \
  --endpoint-url http://localhost:4566

# 03 - Bases de datos NoSQL - DynamoDB

Paso a paso usado para simular Amazon DynamoDB con Floci.

## Pasos

1. Crear archivo de índices secundarios globales (`gsi.json`):

```json
[
  {
    "IndexName": "estado-index",
    "KeySchema": [{"AttributeName": "estado", "KeyType": "HASH"}],
    "Projection": {"ProjectionType": "ALL"}
  },
  {
    "IndexName": "tecnico-index",
    "KeySchema": [{"AttributeName": "tecnico", "KeyType": "HASH"}],
    "Projection": {"ProjectionType": "ALL"}
  },
  {
    "IndexName": "prioridad-index",
    "KeySchema": [{"AttributeName": "prioridad", "KeyType": "HASH"}],
    "Projection": {"ProjectionType": "ALL"}
  }
]
```

2. Crear la tabla DynamoDB ([01_create_table.sh](./01_create_table.sh)):

```bash
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
```

3. Revisar estado de la tabla, motor y los índices secundarios ([02_check_table_state.sh](./02_check_table_state.sh)):

```bash
aws dynamodb describe-table \
  --table-name TicketsSoporte \
  --query "Table.{Nombre:TableName,Estado:TableStatus,Indices:GlobalSecondaryIndexes[*].IndexName}" \
  --output table \
  --endpoint-url http://localhost:4566
```

4. Insertar tickets de ejemplo ([03_insert_tickets.sh](./03_insert_tickets.sh)):

Los datos se cargan desde archivos JSON individuales a modo de prueba (`tk1.json` a `tk5.json`), uno por cada ticket.

```bash
aws dynamodb put-item --table-name TicketsSoporte --item file://tk1.json --endpoint-url http://localhost:4566
aws dynamodb put-item --table-name TicketsSoporte --item file://tk2.json --endpoint-url http://localhost:4566
aws dynamodb put-item --table-name TicketsSoporte --item file://tk3.json --endpoint-url http://localhost:4566
aws dynamodb put-item --table-name TicketsSoporte --item file://tk4.json --endpoint-url http://localhost:4566
aws dynamodb put-item --table-name TicketsSoporte --item file://tk5.json --endpoint-url http://localhost:4566
```

Ejemplo de estructura de un ítem (`tk1.json`):

```json
{
  "ticketId":      {"S": "TK-2026-0001"},
  "clienteId":     {"S": "CL-001"},
  "departamento":  {"S": "Ventas"},
  "categoria":     {"S": "Software"},
  "prioridad":     {"S": "Alta"},
  "estado":        {"S": "Abierto"},
  "tecnico":       {"S": "Carlos Perez"},
  "fechaCreacion": {"S": "2026-06-28"},
  "descripcion":   {"S": "Error al iniciar sesion en el CRM"}
}
```

El campo `clienteId` referencia al cliente almacenado en la base relacional RDS del proyecto (`acme-postgres`), conectando ambas bases de datos sin duplicar información.

5. Verificar datos cargados ([04_scan_table.sh](./04_scan_table.sh)):

```bash
aws dynamodb scan \
  --table-name TicketsSoporte \
  --endpoint-url http://localhost:4566
```

6. Consultar tickets por estado usando `estado-index` ([05_query_by_estado.sh](./05_query_by_estado.sh)):

```bash
aws dynamodb query \
  --table-name TicketsSoporte \
  --index-name estado-index \
  --key-condition-expression "estado = :e" \
  --expression-attribute-values '{ ":e": {"S": "Abierto"} }' \
  --endpoint-url http://localhost:4566
```

7. Consultar tickets por técnico usando `tecnico-index` ([06_query_by_tecnico.sh](./06_query_by_tecnico.sh)):

```bash
aws dynamodb query \
  --table-name TicketsSoporte \
  --index-name tecnico-index \
  --key-condition-expression "tecnico = :t" \
  --expression-attribute-values '{ ":t": {"S": "Carlos Perez"} }' \
  --endpoint-url http://localhost:4566
```

8. Consultar tickets por prioridad usando `prioridad-index` ([07_query_by_prioridad.sh](./07_query_by_prioridad.sh)):

```bash
aws dynamodb query \
  --table-name TicketsSoporte \
  --index-name prioridad-index \
  --key-condition-expression "prioridad = :p" \
  --expression-attribute-values '{ ":p": {"S": "Critica"} }' \
  --endpoint-url http://localhost:4566
```

9. Crear backup exportando todos los ítems a JSON ([08_create_backup.sh](./08_create_backup.sh)):

```bash
mkdir -p backups

aws dynamodb scan \
  --table-name TicketsSoporte \
  --endpoint-url http://localhost:4566 \
  --output json > backups/tickets_backup_$(date +%F_%H%M).json

echo "Backup generado en backups/"
```

El archivo se genera en `03_dynamodb/backups/`.

## Evidencia esperada

- Tabla `TicketsSoporte` creada con `TableStatus: ACTIVE`.
- 3 índices secundarios globales (`estado-index`, `tecnico-index`, `prioridad-index`) con `IndexStatus: ACTIVE`.
- 5 tickets insertados correctamente (`Count: 5` en el scan).
- Consultas por cada índice retornando resultados distintos según el filtro aplicado.
- Backup `.json` generado en la carpeta `backups/`.

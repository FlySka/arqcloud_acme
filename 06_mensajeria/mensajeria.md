# 06 - Notificacion y mensajeria

Paso a paso usado para simular SNS, SQS y DLQ en Floci.

Antes de comenzar, Floci debe estar corriendo y la AWS CLI debe apuntar a `http://localhost:4566`.

Ejecutar los bloques en la misma terminal para conservar variables como `TOPIC_ARN`, `QUEUE_URL`, `QUEUE_ARN`, `DLQ_URL` y `DLQ_ARN`. Si se usan los archivos `.sh`, usar `source` en los pasos que crean variables.

## Pasos

1. Crear el tema SNS ([01_create_topic_sns.sh](./01_create_topic_sns.sh)):

```bash
TOPIC_ARN=$(aws sns create-topic \
  --name acme-alertas-topic \
  --query 'TopicArn' \
  --output text)

echo $TOPIC_ARN
```

2. Crear la cola SQS principal ([02_create_queue_sqs.sh](./02_create_queue_sqs.sh)):

```bash
QUEUE_URL=$(aws sqs create-queue \
  --queue-name acme-alertas-queue \
  --attributes VisibilityTimeout=5,MessageRetentionPeriod=345600 \
  --query 'QueueUrl' \
  --output text)

echo $QUEUE_URL
```

3. Obtener el ARN de la cola SQS ([03_get_arn.sh](./03_get_arn.sh)):

```bash
QUEUE_ARN=$(aws sqs get-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

echo $QUEUE_ARN
```

4. Crear la Dead Letter Queue ([04_create_dlq.sh](./04_create_dlq.sh)):

```bash
DLQ_URL=$(aws sqs create-queue \
  --queue-name acme-alertas-dlq \
  --query 'QueueUrl' \
  --output text)

DLQ_ARN=$(aws sqs get-queue-attributes \
  --queue-url "$DLQ_URL" \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

echo $DLQ_URL
echo $DLQ_ARN
```

5. Configurar la politica de reintentos hacia la DLQ ([05_create_policy.sh](./05_create_policy.sh)):

```bash
cat > redrive-attributes.json <<EOF
{
  "RedrivePolicy": "{\"deadLetterTargetArn\":\"$DLQ_ARN\",\"maxReceiveCount\":\"3\"}"
}
EOF


aws --endpoint-url=http://localhost:4566 sqs set-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attributes file://redrive-attributes.json

aws --endpoint-url=http://localhost:4566 sqs get-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attribute-names RedrivePolicy \
  --output json
```

6. Suscribir la cola SQS al tema SNS ([06_sub_sqs_sns.sh](./06_sub_sqs_sns.sh)):

```bash
SUBSCRIPTION_ARN=$(awslocal sns subscribe \
  --topic-arn "$TOPIC_ARN" \
  --protocol sqs \
  --notification-endpoint "$QUEUE_ARN" \
  --query 'SubscriptionArn' \
  --output text)

echo $SUBSCRIPTION_ARN

aws sns list-subscriptions
```

7. Publicar una alerta de prueba ([07_pub_test_alert.sh](./07_pub_test_alert.sh)):

```bash
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --subject "Alerta CPU Alta" \
  --message '{"servicio":"api-acme","tipo":"CPU_ALTA","valor":"85%","severidad":"alta","accion":"revisar escalabilidad"}'
```

8. Leer mensajes desde SQS ([08_read_msjs_sqs.sh](./08_read_msjs_sqs.sh)):

```bash
awslocal sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --max-number-of-messages 10 \
  --attribute-names All \
  --message-attribute-names All \
  --wait-time-seconds 2 \
  --output json
```

9. Simular reintentos y revisar la DLQ ([09_simulate_retries_dlq.sh](./09_simulate_retries_dlq.sh)):

```bash
for i in 1 2 3 4; do
  echo "Intento $i"
  aws sqs receive-message \
    --queue-url "$QUEUE_URL" \
    --max-number-of-messages 1 \
    --attribute-names ApproximateReceiveCount \
    --wait-time-seconds 2
  sleep 6
done


aws sqs receive-message \
  --queue-url "$DLQ_URL" \
  --max-number-of-messages 10 \
  --attribute-names All \
  --wait-time-seconds 2 \
  --output json
```

## Evidencia esperada

- Tema SNS `acme-alertas-topic` creado.
- Cola SQS `acme-alertas-queue` creada.
- DLQ `acme-alertas-dlq` creada.
- Suscripcion SNS hacia SQS creada.
- Mensaje de alerta publicado y recibido desde SQS.
- Politica `RedrivePolicy` configurada con `maxReceiveCount` igual a `3`.

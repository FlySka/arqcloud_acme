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
QUEUE_URL=$(aws sqs create-queue \
  --queue-name acme-alertas-queue \
  --attributes VisibilityTimeout=5,MessageRetentionPeriod=345600 \
  --query 'QueueUrl' \
  --output text)

echo $QUEUE_URL
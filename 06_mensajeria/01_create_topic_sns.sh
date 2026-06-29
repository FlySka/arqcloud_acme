TOPIC_ARN=$(aws sns create-topic \
  --name acme-alertas-topic \
  --query 'TopicArn' \
  --output text)

echo $TOPIC_ARN
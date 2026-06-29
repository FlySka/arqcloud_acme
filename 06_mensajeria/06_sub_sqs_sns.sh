SUBSCRIPTION_ARN=$(awslocal sns subscribe \
  --topic-arn "$TOPIC_ARN" \
  --protocol sqs \
  --notification-endpoint "$QUEUE_ARN" \
  --query 'SubscriptionArn' \
  --output text)

echo $SUBSCRIPTION_ARN

aws sns list-subscriptions
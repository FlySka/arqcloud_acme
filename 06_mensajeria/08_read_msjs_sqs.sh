awslocal sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --max-number-of-messages 10 \
  --attribute-names All \
  --message-attribute-names All \
  --wait-time-seconds 2 \
  --output json
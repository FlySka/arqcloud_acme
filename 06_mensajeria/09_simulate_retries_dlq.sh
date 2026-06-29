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
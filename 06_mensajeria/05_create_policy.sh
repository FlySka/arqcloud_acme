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
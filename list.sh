#!/bin/bash

STREAM_NAME="<your-stream-name>"

# Step 1: Get all shard IDs
SHARDS=$(aws kinesis list-shards --stream-name $STREAM_NAME --query "Shards[].ShardId" --output text)

# Step 2: Process each shard
for SHARD_ID in $SHARDS; do
  echo "Processing Shard: $SHARD_ID"

  # Step 2.1: Get initial ShardIterator
  SHARD_ITERATOR=$(aws kinesis get-shard-iterator \
    --stream-name $STREAM_NAME \
    --shard-id $SHARD_ID \
    --shard-iterator-type TRIM_HORIZON \
    --query "ShardIterator" \
    --output text)

  # Step 2.2: Iterate through records
  while [ "$SHARD_ITERATOR" != "null" ]; do
    # Get records from the current ShardIterator
    RESPONSE=$(aws kinesis get-records --shard-iterator $SHARD_ITERATOR --output json)

    # Extract SequenceNumber and Data
    SEQUENCE_NUMBERS=$(echo "$RESPONSE" | jq -r '.Records[] | {SequenceNumber: .SequenceNumber, Data: .Data}')
    SHARD_ITERATOR=$(echo "$RESPONSE" | jq -r '.NextShardIterator')

    # Print Sequence Numbers and Data
    echo "Records from Shard $SHARD_ID:"
    echo "$SEQUENCE_NUMBERS" | jq '.'

    # Optional: Sleep to avoid exceeding the Kinesis API rate limit
    sleep 1
  done
done

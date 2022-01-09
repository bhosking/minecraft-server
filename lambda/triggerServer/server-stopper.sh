#!/bin/bash
set -x -e

while :
do
  sleep 299
  screen -S minecraft-server -p 0 -X stuff 'list\n'
  sleep 1
  num_empty=$(tail -n 2 /minecraft/logs/latest.log | grep -e '^\[.\{8\}\] \[Server thread/INFO]: There are 0 of a max of' -c) || true
  if [[ "$num_empty" -eq 2 ]]
  then
    break
  fi
done

# Using EOF here to not match parent's EOL
cat > expression-attribute-values-server-stopper.json <<EOF
{
    ":stopped": {
        "S": "stopped"
    }
}
EOF
# SERVERS_TABLE and AWS_REGION will be replaced by lambda, and json files were set by user data
aws dynamodb update-item \
    --region "${AWS_REGION}" \
    --table-name "${SERVERS_TABLE}" \
    --key file://key.json \
    --update-expression "SET server_status = :stopped REMOVE ipv4_address" \
    --expression-attribute-values file://expression-attribute-values-server-stopper.json

screen -S minecraft-server -p 0 -X stuff 'stop\n'

while :
do
  num_java=$(pgrep java -c) || true
  if [[ "$num_java" -eq 0 ]]
  then
    break
  fi
  sleep 1
done

# SERVERS_BUCKET and SERVER_ID will be replaced by lambda
tar -czf "${SERVER_ID}.tar.gz" minecraft/
aws s3 cp "${SERVER_ID}.tar.gz" "s3://${SERVERS_BUCKET}/"

shutdown -h now

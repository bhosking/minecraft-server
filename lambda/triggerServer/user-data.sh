#!/bin/bash
set -x -e
apt update
apt install -y awscli openjdk-17-jre-headless
# SERVERS_BUCKET and SERVER_ID will be replaced by lambda
aws s3 cp "s3://${SERVERS_BUCKET}/${SERVER_ID}.tar.gz" .
tar -xzf "${SERVER_ID}.tar.gz"
cd minecraft
screen -dmS minecraft-server
screen -S minecraft-server -p 0 -X stuff 'java -Xmx2048M -Xms2048M -jar server.jar nogui\n'
cd ..
IPV4_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

cat > key.json <<EOL
{
    "id": {
        "S": "${SERVER_ID}"
    }
}
EOL

cat > expression-attribute-values-user-data.json <<EOL
{
    ":running": {
        "S": "running"
    },
    ":ipv4_address": {
        "S": "${IPV4_ADDRESS}"
    }
}
EOL

# SERVERS_TABLE and AWS_REGION will be replaced by lambda
aws dynamodb update-item \
    --region "${AWS_REGION}" \
    --table-name "${SERVERS_TABLE}" \
    --key file://key.json \
    --update-expression "SET server_status = :running, ipv4_address = :ipv4_address" \
    --expression-attribute-values file://expression-attribute-values-user-data.json


cat > server-stopper.sh <<'EOL'
${SERVER_STOPPER}
EOL

chmod +x server-stopper.sh
screen -dmS server-stopper
screen -S server-stopper -p 0 -X stuff './server-stopper.sh\n'

import json
import os

import boto3
from botocore.exceptions import ClientError


dynamodb = boto3.client('dynamodb')
ec2 = boto3.resource('ec2')

BASE_AMI = os.environ['BASE_AMI']
INSTANCE_PROFILE = os.environ['INSTANCE_PROFILE']
INSTANCE_TYPE = os.environ['INSTANCE_TYPE']
SECURITY_GROUP = os.environ['SECURITY_GROUP']
SERVER_MEMORY = os.environ['SERVER_MEMORY']
SERVERS_BUCKET = os.environ['SERVERS_BUCKET']
SERVERS_TABLE = os.environ['SERVERS_TABLE']
SSH_KEY_PAIR_NAME = os.environ['SSH_KEY_PAIR_NAME']


HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'text/html',
}


def bundle_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': HEADERS,
        'body': body,
        "isBase64Encoded": False,
    }


def get_server_status(server_id):
    kwargs = {
        'TableName': SERVERS_TABLE,
        'Key': {
            'id': {
                'S': server_id,
            },
        },
        'ProjectionExpression': ','.join([
            'server_status',
            'ipv4_address',
        ]),
    }
    print('Calling dynamodb.get_item with kwargs: {}'.format(json.dumps(kwargs)))
    response = dynamodb.get_item(**kwargs)
    print(f"Received response: {json.dumps(response, default=str)}")
    return response.get('Item')


def trigger_server(server_id):
    while True:
        if start_server(server_id):
            break
        else:
            server_status = get_server_status(server_id)
            if server_status is None:
                return bundle_response(
                    404,
                    '<title>Minecraft Server Access</title>'
                    '<h2>Server not found</h2>'
                )
            status = server_status['server_status']['S']
            if status == 'stopped':
                # Unlikely, but maybe the server was stopped between the call to start the server and the status query
                # Just start it again
                continue
            elif status == 'starting':
                break
            elif status == 'running':
                ipv4_address = server_status['ipv4_address']['S']
                return bundle_response(
                    200,
                    '<title>Minecraft Server Access</title>'
                    f'<h1>{ipv4_address}</h1>'
                )
            else:
                return bundle_response(
                    500,
                    '<title>Minecraft Server Access</title>'
                    f'<h2>Server has unrecognised status "{status}"</h2>'
                )
    return bundle_response(
        200,
        '<title>Minecraft Server Access</title>'
        '<h2>Server is starting...</h2>'
        '<h3>It will be running in a minute or so, refresh this page to get the ip address when it\'s ready</h3>'
        '<h3><a href="#" onclick=refreshPage()>Refresh</a></h3>'
        '<script>function refreshPage() {window.location.reload();}</script>'
    )


def start_server(server_id):
    if not update_dynamodb(server_id):
        return False
    with open('user-data.sh') as user_data_file:
        user_data = user_data_file.read()
    with open('server-stopper.sh') as server_stopper_file:
        server_stopper = server_stopper_file.read()
    user_data = user_data.replace('${SERVER_STOPPER}', server_stopper)
    user_data = user_data.replace('${AWS_REGION}', os.environ['AWS_REGION'])
    user_data = user_data.replace('${SERVER_ID}', server_id)
    user_data = user_data.replace('${SERVER_MEMORY}', SERVER_MEMORY)
    user_data = user_data.replace('${SERVERS_BUCKET}', SERVERS_BUCKET)
    user_data = user_data.replace('${SERVERS_TABLE}', SERVERS_TABLE)
    kwargs = {
        'IamInstanceProfile': {
            'Name': INSTANCE_PROFILE,
        },
        'ImageId': BASE_AMI,
        'InstanceInitiatedShutdownBehavior': 'terminate',
        'InstanceMarketOptions': {
            'MarketType': 'spot',
            'SpotOptions': {
                'SpotInstanceType': 'one-time'
            },
        },
        'InstanceType': INSTANCE_TYPE,
        'KeyName': SSH_KEY_PAIR_NAME,
        'MaxCount': 1,
        'MinCount': 1,
        'SecurityGroups': [
            SECURITY_GROUP,
        ],
        'TagSpecifications': [
            {
                'ResourceType': 'instance',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': 'Minecraft Server',
                    },
                    {
                        'Key': 'Server ID',
                        'Value': server_id,
                    },
                ],
            },
        ],
        'UserData': user_data,
    }
    if INSTANCE_TYPE.startswith('t'):
        kwargs['CreditSpecification'] = {
            'CpuCredits': 'standard',
        }
    print('Calling ec2.create_instances with kwargs: {}'.format(json.dumps(kwargs)))
    response = ec2.create_instances(**kwargs)
    print(f"Received response: {json.dumps(response, default=str)}")
    return True


def update_dynamodb(server_id):
    kwargs = {
        'TableName': SERVERS_TABLE,
        'Key': {
            'id': {
                'S': server_id,
            },
        },
        'UpdateExpression': 'SET server_status = :starting',
        'ConditionExpression': 'server_status = :stopped',
        'ExpressionAttributeValues': {
            ':starting': {
                'S': 'starting',
            },
            ':stopped': {
                'S': 'stopped',
            },
        },
    }
    print('Updating table: {}'.format(json.dumps(kwargs)))
    try:
        response = dynamodb.update_item(**kwargs)
    except ClientError as e:
        print("Received error: {}".format(json.dumps(e.response, default=str)))
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            print("Server has already been started.")
            return False
        else:
            raise e
    print(f"Received response: {json.dumps(response, default=str)}")
    return True


def lambda_handler(event, context):
    print('Event Received: {}'.format(json.dumps(event)))
    server_id = event['pathParameters']['ServerId']
    response = trigger_server(server_id)
    print('Returning Response: {}'.format(json.dumps(response)))
    return response

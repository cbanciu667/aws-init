import os
import ast
import json
import time
import boto3
import cfnresponse
from boto3 import client as boto3_client
from botocore.exceptions import ClientError

def cfnrespond(event, context, response_status, response_data, physical_resource_id = None, no_echo = None):
    try:
        cfnresponse.send(event, context, response_status, response_data, physical_resource_id, no_echo)
    except Exception as e:
        print(e)
        pass
    return response_data

def lambda_handler(event, context):
    region_name=os.environ["AWS_REGION"]
    resp_data = {'Response': 'OK'}
    response_status = cfnresponse.SUCCESS
    if 'RequestType' in event.keys():
        secret_request_values = event['ResourceProperties']
        if event['ResourceProperties'] == 'Delete':
            return cfnrespond(event, context, response_status, resp_data, '')
    else:
        secret_request_values = event
    # build response data and status
    secret_name = secret_request_values['secretname']
    secret_value = secret_request_values['secretvalue']
    lambda_response = 'emptyResponse'
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name,
    )
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            print("The requested secret " + secret_name + " was not found")
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            print("The request was invalid due to:", e)
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            print("The request had invalid params:", e)
    else:
        # Secrets Manager decrypts the secret value using the associated KMS CMK
        # Depending on whether the secret was a string or binary, only one of these fields will be populated
        if 'SecretString' in get_secret_value_response:
            text_secret_data = get_secret_value_response['SecretString']
            lambda_response = text_secret_data
        else:
            binary_secret_data = get_secret_value_response['SecretBinary']
            lambda_response = binary_secret_data
    lambda_response = ast.literal_eval(lambda_response) 
    lambda_response = lambda_response[secret_value]
    # returning final response
    try:
        resp_data = {'Response': lambda_response}
    except Exception as e:
        print(e)
        pass
    return cfnrespond(event, context, response_status, resp_data, '')

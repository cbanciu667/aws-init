import json
import boto3
import json
import OpenSSL
import datetime
from boto3 import client as boto3_client

aws_region = str(os.environ['LAMBDA_REGION'])
lambda_client = boto3_client('lambda', region_name=aws_region)
pem_type = OpenSSL.crypto.FILETYPE_PEM

def lambda_handler(event, context):
    print('Running myproject.com lambda: ')
    value = 1
    return value
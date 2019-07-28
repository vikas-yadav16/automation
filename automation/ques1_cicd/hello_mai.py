import json
import boto3
import os

def lambda_handler(event, context):
    # TODO implement
    # Create an SNS client
    sns = boto3.client('sns')

    # Publish a simple message to the specified SNS topic
    response = sns.publish(
    TopicArn=os.environ['SNS_ARN'],    
    Message='Hello World!',    
    )

    # Print out the response
    print(response)
    
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
}

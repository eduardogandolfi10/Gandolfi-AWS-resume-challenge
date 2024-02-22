import json
import boto3

dynamodb = boto3.resource('dynamodb')
ddbTableName = 'TerraDB'
table = dynamodb.Table(ddbTableName)

def lambda_handler(event, context):
    
    print(event)
    print('I am stupid')
    name = event["queryStringParameters"]["name"]
    print(name)
    response = table.get_item(Key= {'Name' : name} )
    count = response["Item"]["view_count"]
    print(count)
    

    new_count = str(int(count)+1)
    response = table.update_item(
        Key={'Name': name},
        UpdateExpression='set view_count = :c',
        ExpressionAttributeValues={':c': new_count},
        ReturnValues='UPDATED_NEW'
        )

    return {
        'statusCode': 200,
         'headers': { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*' 
    },
        'body': json.dumps({
        name: new_count
        }
            )
    }
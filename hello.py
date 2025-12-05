import json

def lambda_handler(event, context):
    # Ito ang sasabihin ng AI mo sa web browser
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({
            "message": "Hello Stan! Official Cloud Engineer na ako!",
            "status": "Online",
            "powered_by": "AWS Lambda + Terraform"
        })
    }
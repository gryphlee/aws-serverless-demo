import json

def lambda_handler(event, context):
    # Ito ang sasabihin ng AI mo sa web browser
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({
            "message": "I am now a CI/CD Deployed AI! 100x Engineer Status Unlocked",
            "status": "Online",
            "powered_by": "AWS Lambda + Terraform"
        })
    }
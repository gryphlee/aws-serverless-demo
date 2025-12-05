terraform {
  backend "s3" {
    bucket = "stan-terraform-state-unique-123" # <--- PALITAN NG BUCKET NAME MO
    key    = "terraform.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# --- PART 1: PACKAGING (Zip the code) ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "hello.py"
  output_path = "hello.zip"
}

# --- PART 2: SECURITY (IAM Role) ---
resource "aws_iam_role" "iam_for_lambda" {
  name = "stan_lambda_role_v2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# --- PART 3: COMPUTE (The Lambda Function) ---
resource "aws_lambda_function" "my_api_backend" {
  filename      = "hello.zip"
  function_name = "Stan-Public-API"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "hello.lambda_handler"
  runtime       = "python3.9"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# --- PART 4: THE FRONT DOOR (API Gateway) ---
# 1. Create the API
resource "aws_apigatewayv2_api" "http_api" {
  name          = "Stan-Serverless-API"
  protocol_type = "HTTP"
}

# 2. Create the Stage (Default environment)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# 3. Connect API to Lambda (Integration)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.my_api_backend.invoke_arn
}

# 4. Create the Route (The URL path "/")
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 5. Permission: Allow API Gateway to wake up Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_api_backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# --- OUTPUT: Show the URL after deploy ---
output "api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

# 3. The Lambda Function: Ito mismo yung Python sa Cloud
resource "aws_lambda_function" "test_lambda" {
  filename      = "hello.zip"
  function_name = "Stan-Python-Automator"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "hello.lambda_handler" # File name + Function name
  runtime       = "python3.9"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}
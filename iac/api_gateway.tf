# api gateway rest api
resource "aws_api_gateway_rest_api" "spotify_api" {
   name        = "spotify-api"
}

resource "aws_api_gateway_resource" "search" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  parent_id   = aws_api_gateway_rest_api.spotify_api.root_resource_id
  path_part   = "search"
}



resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.spotify_api.id
  resource_id   = aws_api_gateway_resource.search.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.spotify_api.id
  resource_id   = aws_api_gateway_resource.search.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  resource_id = aws_api_gateway_resource.search.id
  http_method = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri = aws_lambda_function.lambda.invoke_arn
  
  depends_on = [ aws_api_gateway_method.get ]
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  resource_id = aws_api_gateway_resource.search.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

   request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  resource_id = aws_api_gateway_resource.search.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST'"
    ################# CHANGE TO CLOUDFRONT URL ##################################
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  resource_id = aws_api_gateway_resource.search.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"


  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.options_integration, aws_api_gateway_integration.get_integration]
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  stage_name = "dev"
}
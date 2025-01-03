# lambda role
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# POLICIES FOR RESOURCES ACCESS / USING AWS PREDEFINED POLICIES
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ecr_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# main lambda resource 
resource "aws_lambda_function" "lambda" {
  function_name = "spotify_lambda"
  package_type  = "Image"
  image_uri     = var.image_uri
  role          = aws_iam_role.lambda_role.arn
  timeout       = 120
  memory_size   = 128

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "${aws_dynamodb_table.dynamodb.name}"
      REGION              = "${var.aws_region}"
      SPOTIFY_CLIENT_ID = "${var.client_id}"
      SPOTIFY_CLIENT_SECRET = "${var.client_secret}"
    }
  }

   vpc_config {
    subnet_ids         = ["${data.terraform_remote_state.networking.outputs.priv_sub_id}"]
    security_group_ids = ["${aws_security_group.lambda_sg.id}"]  
  }


  tags = {
    Name        = "spotify_lambda"
    Environment = "${var.env}"
  }
}

# security group for lambda
resource "aws_security_group" "lambda_sg" {
  name = "lambda_sg"
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.0.0/24"] 
  }

}

# lambda policy for network interface beause of security group
resource "aws_iam_policy" "lambda_vpc_policy" {
  name        = "spotify_lambda_vpc_policy"
  description = "Allow Lambda to interact with VPC resources"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_vpc_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# lambda permission for api gateway invoke
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.spotify_api.execution_arn}/*/*"
}
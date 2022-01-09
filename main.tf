provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      Project = "Minecraft Server"
    }
  }
}

module "lambda-triggerServer" {
  source = "github.com/bhosking/terraform-aws-lambda"

  function_name = "triggerServer"
  description = "Starts server is one is not already running, and returns ip address if one is."
  handler = "lambda_function.lambda_handler"
  runtime = "python3.9"
  architectures = ["arm64"]
  memory_size = 256
  timeout = 28
  policy = {
    json = data.aws_iam_policy_document.lambda-triggerServer.json
  }
  source_path = "${path.module}/lambda/triggerServer"

  environment = {
    variables = {
      BASE_AMI = var.base-ami
      INSTANCE_PROFILE = aws_iam_instance_profile.server-ec2.name
      INSTANCE_TYPE = var.instance-type
      SECURITY_GROUP = aws_security_group.server-sg.name
      SERVERS_TABLE = aws_dynamodb_table.servers.name
      SERVERS_BUCKET = aws_s3_bucket.servers-bucket.bucket
      SSH_KEY_PAIR_NAME = var.ssh-key-pair-name
    }
  }
}

#
# Lambda triggerServer
#

data aws_iam_policy_document lambda-triggerServer {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
    ]
    resources = [
      aws_dynamodb_table.servers.arn,
    ]
  }

  statement {
    actions = [
      "ec2:CreateTags",
      "ec2:RunInstances",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.server-ec2.arn,
    ]
  }
}


#
# EC2 assume role
#

data "aws_iam_policy_document" "ec2-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


#
# server EC2 instance role
#

data "aws_iam_policy_document" "server-ec2" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.servers-bucket.arn}/*",
    ]
  }

  statement {
    actions = [
      "dynamodb:UpdateItem",
    ]
    resources = [
      aws_dynamodb_table.servers.arn,
    ]
  }
}

resource "aws_iam_policy" "server-ec2" {
  name = "ServerEc2Policy"
  policy = data.aws_iam_policy_document.server-ec2.json
}

resource "aws_iam_role" "server-ec2" {
  name = "ServerEc2AccessRole"
  assume_role_policy = data.aws_iam_policy_document.ec2-assume-role.json
}

resource "aws_iam_role_policy_attachment" "server-ec2" {
  role = aws_iam_role.server-ec2.name
  policy_arn = aws_iam_policy.server-ec2.arn
}

resource "aws_iam_instance_profile" "server-ec2" {
  name = "ServerEc2InstanceProfile"
  role = aws_iam_role.server-ec2.name
  depends_on = [
    aws_iam_role_policy_attachment.server-ec2,
  ]
}

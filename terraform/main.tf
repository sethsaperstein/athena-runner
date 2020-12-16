terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "seth-saperstein"

    workspaces {
      name = "athena-runner"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


resource "aws_sfn_state_machine" "athena_runner" {
  name     = "athena-runner-state-machine"
  role_arn = aws_iam_role.step_function_role.arn

  definition = <<EOF
{
  "Comment": "A state machine for running athena queries",
  "StartAt": "submit_query",
  "States": {
    "submit_query": {
      "Type": "Task",
      "Resource": "${module.submit_query_lambda.aws_lambda_function.arn}",
      "Next": "wait"
    },
    "wait": {
        "Type": "Wait",
        "Seconds": ${var.seconds_to_wait},
        "Next": "poll_status"
    },
    "status_check": {
        "Type": "Task",
        "Resource": "${module.status_check_lambda.aws_lambda_function.arn}",
        "Next": "check_complete"
    },
    "check_complete": {
        "Type": "Choice",
        "Default": "wait",
        "Choices": [
            {
                "Variable": "$.status",
                "StringEquals": "FAILED",
                "Next": "failed"
            },
            {
                "Variable": "$.status",
                "StringEquals": "SUCCEEDED",
                "Next": "get_result"
            }
        ]
    },
    "failed": {
        "Type": "Fail",
        "Cause": "Athena execution failed",
        "Error": "Athena execution failed"
    },
    "get_result": {
        "Type": "Task",
        "Resource": "${module.get_result_lambda.aws_lambda_function.arn}",
        "End": true
    }
  }
}
EOF
}

resource "aws_iam_role" "step_function_role" {
  name               = "athena-runner-step-function-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "StepFunctionAssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "athena-runner-step-function-policy"
  role = aws_iam_role.step_function_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": [
          ${module.submit_query_lambda.aws_lambda_function.arn},
          ${module.status_check_lambda.aws_lambda_function.arn},
          ${module.get_result_lambda.aws_lambda_function.arn}
      ]
    }
  ]
}
EOF
}

module "submit_query_lambda" {
  source = "./modules/lambda"

  bucket            = var.deploy_bucket_name
  s3_key            = var.athena_runner_s3_key
  s3_object_version = var.athena_runner_s3_object_version
  name              = "submit-query"
  handler           = "src.handler.submit_query"
  env_vars = {
    LOG_LEVEL = var.log_level
    ENV_NAME  = var.env_name
  }
}

module "status_check_lambda" {
  source = "./modules/lambda"

  bucket            = var.deploy_bucket_name
  s3_key            = var.athena_runner_s3_key
  s3_object_version = var.athena_runner_s3_object_version
  name              = "status-check"
  handler           = "src.handler.status_check"
  env_vars = {
    LOG_LEVEL = var.log_level
    ENV_NAME  = var.env_name
  }
}

module "get_result_lambda" {
  source = "./modules/lambda"

  bucket            = var.deploy_bucket_name
  s3_key            = var.athena_runner_s3_key
  s3_object_version = var.athena_runner_s3_object_version
  name              = "get-result"
  handler           = "src.handler.get_result"
  env_vars = {
    LOG_LEVEL = var.log_level
    ENV_NAME  = var.env_name
  }
}

resource "aws_iam_policy" "this" {
  name        = "athena_runner"
  path        = "/"
  description = "Allows lambda to execute athena queries and modify results"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:StartQueryExecution"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetDatabase",
        "glue:GetDatabases",
        "glue:GetTable",
        "glue:GetTables",
        "glue:GetPartition",
        "glue:GetPartitions"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:ListMultipartUploadParts",
        "s3:PutObject"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "this" {
  name = "athena-runner-lambda-attachment"
  roles = [
    module.submit_query_lambda.aws_iam_role.name,
    module.status_check_lambda.aws_iam_role.name,
    module.get_result_lambda.aws_iam_role.name
  ]
  policy_arn = aws_iam_policy.this.arn
}

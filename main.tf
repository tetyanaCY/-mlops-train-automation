terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  lambda_validate_name   = "${var.project_name}-validate"
  lambda_log_metrics_name = "${var.project_name}-log-metrics"
  sfn_name               = "${var.project_name}-train-pipeline"
}

# ---------- IAM role for Lambda ----------
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_name}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Basic execution policy for logs
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------- Lambda: Validate ----------
resource "aws_lambda_function" "validate" {
  function_name = local.lambda_validate_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "validate.lambda_handler"
  runtime       = var.lambda_runtime
  filename      = "${path.module}/lambda/validate.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/validate.zip")
  memory_size   = var.lambda_memory
  timeout       = var.lambda_timeout
  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

# ---------- Lambda: Log Metrics ----------
resource "aws_lambda_function" "log_metrics" {
  function_name = local.lambda_log_metrics_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "log_metrics.lambda_handler"
  runtime       = var.lambda_runtime
  filename      = "${path.module}/lambda/log_metrics.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/log_metrics.zip")
  memory_size   = var.lambda_memory
  timeout       = var.lambda_timeout
  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

# ---------- IAM role for Step Functions ----------
data "aws_iam_policy_document" "sfn_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn_role" {
  name               = "${var.project_name}-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume_role.json
}

# Policy to allow Step Functions to invoke Lambdas
data "aws_iam_policy_document" "sfn_invoke_lambda" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.validate.arn,
      "${aws_lambda_function.validate.arn}:*",
      aws_lambda_function.log_metrics.arn,
      "${aws_lambda_function.log_metrics.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "sfn_invoke_lambda" {
  name   = "${var.project_name}-sfn-invoke-lambda"
  role   = aws_iam_role.sfn_role.id
  policy = data.aws_iam_policy_document.sfn_invoke_lambda.json
}

# ---------- Step Functions State Machine ----------
resource "aws_sfn_state_machine" "train" {
  name     = local.sfn_name
  role_arn = aws_iam_role.sfn_role.arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "ML training pipeline: ValidateData -> LogMetrics"
    StartAt = "ValidateData"
    States = {
      ValidateData = {
        Type       = "Task"
        Resource   = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.validate.arn
          # Pass full execution input to Lambda as event
          "Payload.$"  = "$"
        }
        # Unwrap Lambda's {"Payload": ...} to just the payload
        OutputPath = "$.Payload"
        Next       = "LogMetrics"
      }
      LogMetrics = {
        Type       = "Task"
        Resource   = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.log_metrics.arn
          "Payload.$"  = "$"
        }
        OutputPath = "$.Payload"
        End        = true
      }
    }
  })
}

# ---------- Helpful outputs ----------
output "state_machine_arn" {
  description = "ARN of the training Step Function"
  value       = aws_sfn_state_machine.train.arn
}

output "lambda_validate_name" {
  value = aws_lambda_function.validate.function_name
}

output "lambda_log_metrics_name" {
  value = aws_lambda_function.log_metrics.function_name
}

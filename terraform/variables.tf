variable "project_name" {
  description = "Base name/prefix for resources"
  type        = string
  default     = "mlops-train-automation"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "eu-central-1"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "lambda_timeout" {
  description = "Lambda timeout (seconds)"
  type        = number
  default     = 60
}

variable "lambda_memory" {
  description = "Lambda memory (MB)"
  type        = number
  default     = 256
}

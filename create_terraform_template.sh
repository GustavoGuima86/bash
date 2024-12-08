#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 <repository_name>"
  exit 1
}

# Check for correct number of arguments
if [ $# -ne 1 ]; then
  usage
fi

# Assign the argument to a variable
REPO_NAME=$1

# Create the main project folder structure
mkdir -p "$REPO_NAME/environments"
mkdir -p "$REPO_NAME/modules/template"
mkdir -p "$REPO_NAME/environments/dev"

# --- Create readme ---
echo "Creating readme.MD in $REPO_NAME/"

# main.tf - Defines the resources in the template module
cat > "$REPO_NAME/Readme.MD" <<EOL
## Example terraform

This is a simple terraform project.

## Basic Commands
\`\`\`console
terraform init
terraform plan -var-file=dev/dev.tfvars
terraform apply -var-file=dev/dev.tfvars
\`\`\`

EOL

# --- Create files for the module: template ---
echo "Creating template module in $REPO_NAME/modules/template"

# main.tf - Defines the resources in the template module
cat > "$REPO_NAME/modules/template/main.tf" <<EOL
resource "aws_s3_bucket" "template-bucket" {
  bucket = "\${var.bucket_name}"
}
EOL

# variables.tf - Declares the input variables for the module
cat > "$REPO_NAME/modules/template/variables.tf" <<EOL
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "env" {
  description = "The environment to be deployed"
  type        = string
}
EOL

# outputs.tf - Defines the output values for the module
cat > "$REPO_NAME/modules/template/outputs.tf" <<EOL
output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.template-bucket.bucket
}
EOL

# data.tf - Data sources, for example, retrieving the current region
cat > "$REPO_NAME/modules/template/data.tf" <<EOL
data "aws_region" "current" {}
EOL

# locals.tf - Defines local variables within the module
cat > "$REPO_NAME/modules/template/locals.tf" <<EOL
locals {
  bucket_name_local = "\${var.bucket_name}-\${var.env}"
}
EOL

# providers.tf - AWS provider configuration
cat > "$REPO_NAME/modules/template/providers.tf" <<EOL
EOL

# --- Create environments files ---
echo "Creating environments setup in $REPO_NAME/environments"

# main.tf - Implementing the template module in the environments folder
cat > "$REPO_NAME/environments/main.tf" <<EOL
module "template_module" {
  source     = "../modules/template"
  bucket_name = var.bucket_name
  env         = var.env
}
EOL

# variables.tf - Declares the input variables for the environments
cat > "$REPO_NAME/environments/variables.tf" <<EOL
variable "env" {
  description = "The environment to be deployed"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "my-terraform-bucket"
}
EOL

# outputs.tf - Declares the output values for the environments
cat > "$REPO_NAME/environments/outputs.tf" <<EOL
output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.template_module.bucket_name
}
EOL

# providers.tf - AWS provider configuration for the environments
cat > "$REPO_NAME/environments/providers.tf" <<EOL
provider "aws" {
  region = var.aws_region
}
EOL

# backend.tf - Backend configuration for storing Terraform state in an S3 bucket
cat > "$REPO_NAME/environments/backend.tf" <<EOL
// Enable Backend by creating the s3 bucket before
// https://developer.hashicorp.com/terraform/language/backend/s3
/*
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "state/template.tfstate"
    region = "eu-central-1"
  }
}
*/
EOL

# --- Create the dev environment setup ---
echo "Creating dev environment setup in $REPO_NAME/environments/dev"

# dev.tfvars - Variable values specific to the dev environment
cat > "$REPO_NAME/environments/dev/dev.tfvars" <<EOL
bucket_name = "my-dev-terraform-bucket"
aws_region  = "eu-central-1"
env         = "dev"
EOL


# Final message
echo "Terraform structure created in '$REPO_NAME'."

# Terraform Backend Configuration
# This file configures remote state storage in S3 with DynamoDB locking
# Run terraform init after creating the backend infrastructure manually first

terraform {
  backend "s3" {
    # These values should be set via terraform init -backend-config
    # or via environment variables/terraform.tfvars
    # 
    # Example initialization:
    # terraform init \
    #   -backend-config="bucket=my-terraform-state-bucket" \
    #   -backend-config="key=shared-infrastructure/terraform.tfstate" \
    #   -backend-config="region=us-west-2" \
    #   -backend-config="dynamodb_table=terraform-locks" \
    #   -backend-config="encrypt=true"
    
    # Uncomment and update these values once backend infrastructure exists:
    # bucket         = "shared-infrastructure-terraform-state"
    # key            = "shared-infrastructure/terraform.tfstate"
    # region         = "us-west-2"
    # dynamodb_table = "terraform-locks"
    # encrypt        = true
  }
}

# DynamoDB table for Terraform state locking
# This should be created manually first or in a separate bootstrap configuration
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "terraform-state-locking"
  }
}
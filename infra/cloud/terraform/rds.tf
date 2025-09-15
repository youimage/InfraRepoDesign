# RDS Configuration for Shared Infrastructure
# PostgreSQL database for multiple applications

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Parameter Group for PostgreSQL
resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${var.project_name}-${var.environment}-postgres15"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres-params"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  # Engine configuration
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.environment == "production" ? "db.t3.medium" : "db.t3.micro"

  # Storage configuration
  allocated_storage     = var.environment == "production" ? 100 : 20
  max_allocated_storage = var.environment == "production" ? 1000 : 100
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database configuration
  db_name  = "shared_infrastructure"
  username = "admin"
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = var.environment == "production" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Performance and monitoring
  parameter_group_name        = aws_db_parameter_group.main.name
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_enhanced_monitoring.arn

  # Deletion protection
  deletion_protection = var.environment == "production" ? true : false
  skip_final_snapshot = var.environment != "production"

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Enhanced Monitoring Role for RDS
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Store database credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}-${var.environment}-db-credentials"

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-credentials"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.main.username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
  })
}

# Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_url" {
  description = "Database connection URL"
  value       = "postgresql://${aws_db_instance.main.username}:${random_password.db_password.result}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}
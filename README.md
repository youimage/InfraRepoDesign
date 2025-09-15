# Shared Infrastructure Repository

A comprehensive DevOps infrastructure template for running multiple applications on shared infrastructure, supporting both development and production environments.

## 🏗️ Architecture Overview

This repository provides a complete infrastructure setup that supports:

- **Local Development**: Docker Compose environment with Flask, Node.js, PostgreSQL, and Nginx
- **Production Deployment**: Terraform + Kubernetes for cloud deployment (AWS/GCP/Azure)
- **CI/CD Pipeline**: GitHub Actions with automated lint, test, build, and deploy stages
- **Multi-Application Support**: Easy to add new applications by changing Docker image names or service configurations

## 📁 Repository Structure

```
infra/
├── local/                     # Development Docker Compose environment
│   ├── docker-compose.yml    # Multi-service local setup
│   ├── docker/
│   │   ├── flask.Dockerfile  # Flask application container
│   │   ├── node.Dockerfile   # Node.js application container
│   │   └── nginx/
│   │       └── default.conf  # Nginx reverse proxy configuration
│   └── postgres/
│       └── init.sql          # Database initialization script
│
├── cloud/                     # Production cloud infrastructure
│   ├── terraform/            # Infrastructure as Code (AWS/GCP/Azure)
│   │   ├── vpc.tf           # VPC, subnets, networking
│   │   ├── ecs.tf           # Container orchestration (ECS)
│   │   ├── rds.tf           # Managed PostgreSQL database
│   │   └── s3.tf            # Object storage and CDN
│   └── k8s/                 # Kubernetes manifests
│       ├── base/            # Base Kubernetes configurations
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   └── ingress.yaml
│       └── overlays/        # Environment-specific configs
│           ├── staging/
│           └── production/
│
├── ci-cd/                    # Shared CI/CD pipeline
│   └── github-actions/
│       └── deploy.yml       # Complete CI/CD workflow
│
└── README.md                # This documentation
```

## 🚀 Quick Start

### Local Development Setup

1. **Clone and Configure Environment**
   ```bash
   git clone <repository-url>
   cd shared-infrastructure
   cp .env.example .env
   # Edit .env with your configuration
   ```

2. **Start Development Environment**
   ```bash
   cd infra/local
   docker-compose up -d
   ```

3. **Access Applications**
   - **Nginx Proxy**: http://localhost:80
   - **Flask API**: http://localhost:5000
   - **Node.js App**: http://localhost:3000
   - **PostgreSQL**: localhost:5432

4. **View Logs**
   ```bash
   docker-compose logs -f [service-name]
   ```

### Production Deployment

#### Prerequisites
- AWS/GCP/Azure CLI configured
- Terraform installed
- kubectl configured
- Docker registry access

#### Infrastructure Deployment

1. **Deploy Cloud Infrastructure**
   ```bash
   cd infra/cloud/terraform
   terraform init
   terraform plan -var="environment=production"
   terraform apply
   ```

2. **Deploy Kubernetes Applications**
   ```bash
   cd infra/cloud/k8s/overlays/production
   kustomize build . | kubectl apply -f -
   ```

3. **Verify Deployment**
   ```bash
   kubectl get pods -n production
   kubectl get services -n production
   ```

## 🔧 Configuration

### Environment Variables

Key environment variables (see `.env.example`):

```bash
# Environment Configuration
ENVIRONMENT=development|staging|production
PROJECT_NAME=shared-infrastructure

# Database Configuration
POSTGRES_DB=app_db
POSTGRES_USER=app_user
POSTGRES_PASSWORD=app_password

# Application Configuration
FLASK_ENV=development|production
NODE_ENV=development|production

# Cloud Provider (AWS example)
AWS_REGION=us-west-2
ECS_CLUSTER_NAME=shared-infrastructure
```

### Adding New Applications

To add a new application:

1. **Create Dockerfile** in `infra/local/docker/`
2. **Add service** to `infra/local/docker-compose.yml`
3. **Create Kubernetes deployment** in `infra/cloud/k8s/base/`
4. **Update CI/CD pipeline** to include the new application
5. **Configure routing** in Nginx and Ingress

Example service addition to docker-compose.yml:
```yaml
new-app:
  build:
    context: ./docker
    dockerfile: new-app.Dockerfile
  environment:
    DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
  ports:
    - "8000:8000"
  depends_on:
    postgres:
      condition: service_healthy
  networks:
    - app-network
```

## 🏗️ Infrastructure Components

### Local Development (Docker Compose)
- **PostgreSQL 15**: Shared database with application-specific schemas
- **Nginx**: Reverse proxy with health checks and security headers
- **Flask Application**: Python web application container
- **Node.js Application**: JavaScript/TypeScript application container

### Production (AWS/Terraform + Kubernetes)
- **VPC**: Multi-AZ setup with public/private subnets and NAT gateways
- **ECS/EKS**: Container orchestration with auto-scaling
- **RDS**: Managed PostgreSQL with automated backups and monitoring
- **S3 + CloudFront**: Object storage and global CDN
- **Application Load Balancer**: High-availability load balancing
- **Secrets Manager**: Secure credential storage

### CI/CD Pipeline (GitHub Actions)
- **Lint Stage**: Code quality checks (Python, Node.js, Terraform, Kubernetes)
- **Test Stage**: Automated testing with PostgreSQL integration
- **Build Stage**: Multi-architecture Docker image builds
- **Deploy Stage**: Environment-specific deployments (staging/production)
- **Security Stage**: Vulnerability scanning with Trivy

## 🔐 Security Features

- **Network Isolation**: Private subnets for databases and internal services
- **Encryption**: Data encryption at rest and in transit
- **Secret Management**: AWS Secrets Manager integration
- **Container Security**: Non-root users and minimal attack surface
- **Security Headers**: Comprehensive HTTP security headers in Nginx
- **Vulnerability Scanning**: Automated security scanning in CI/CD

## 📊 Monitoring and Observability

### Built-in Monitoring
- **Health Checks**: Application and database health endpoints
- **Resource Monitoring**: CPU, memory, and storage metrics
- **Log Aggregation**: Centralized logging with retention policies
- **Performance Insights**: Database performance monitoring

### Optional Monitoring Stack (Future Enhancement)
- **Prometheus + Grafana**: Metrics collection and visualization
- **ELK Stack**: Advanced log analysis
- **Jaeger**: Distributed tracing

## 🔄 Environment Management

### Development → Staging → Production

1. **Development**: 
   - Local Docker Compose setup
   - Minimal resource allocation
   - Debug logging enabled
   - Fast feedback loop

2. **Staging**:
   - Kubernetes deployment
   - Production-like environment
   - Integration testing
   - Performance validation

3. **Production**:
   - High availability setup
   - Auto-scaling enabled
   - Security hardening
   - Monitoring and alerting

## 🚀 Deployment Workflows

### Automatic Deployments
- **Feature branches**: No deployment
- **Develop branch**: Auto-deploy to staging
- **Main branch**: Auto-deploy to production (with approval gates)

### Manual Deployments
```bash
# Deploy specific version to staging
kubectl set image deployment/staging-flask-app flask-app=myapp:v1.2.3 -n staging

# Rollback deployment
kubectl rollout undo deployment/prod-flask-app -n production
```

## 🔧 Troubleshooting

### Common Issues

1. **Database Connection Issues**
   ```bash
   # Check database status
   docker-compose ps postgres
   # View database logs
   docker-compose logs postgres
   ```

2. **Application Not Starting**
   ```bash
   # Check application logs
   docker-compose logs flask-app
   # Restart services
   docker-compose restart flask-app
   ```

3. **Kubernetes Deployment Issues**
   ```bash
   # Check pod status
   kubectl get pods -n production
   # View pod logs
   kubectl logs deployment/prod-flask-app -n production
   ```

### Performance Tuning

- **Database**: Adjust connection pool sizes and query optimization
- **Applications**: Monitor memory usage and implement caching
- **Load Balancer**: Configure appropriate health check intervals
- **Auto-scaling**: Fine-tune CPU/memory thresholds

## 🤝 Contributing

1. Follow the established directory structure
2. Add environment-specific configurations in overlays
3. Update documentation for new features
4. Test changes in development environment first
5. Ensure CI/CD pipeline passes all checks

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 📝 License

This infrastructure template is provided as-is for educational and development purposes. Adapt security settings and configurations for production use according to your organization's requirements.
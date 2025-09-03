# Complete DevOps Infrastructure with Full Toolchain

This project demonstrates a comprehensive DevOps infrastructure setup using Terraform to provision AWS resources and automatically configure a complete DevOps toolchain.

## 🛠️ DevOps Toolchain

### ✅ Infrastructure as Code
- **Terraform**: Infrastructure provisioning and management
- **Ansible**: Configuration management and automation

### ✅ CI/CD Pipeline
- **GitHub**: Source code management and version control
- **Jenkins**: Continuous Integration and Continuous Deployment
- **Maven**: Build automation and dependency management

### ✅ Container & Orchestration
- **Docker**: Containerization platform
- **Kubernetes**: Container orchestration
- **Helm Charts**: Kubernetes package manager

### ✅ Code Quality & Security
- **SonarQube**: Code quality and security analysis
- **JFrog Artifactory**: Binary repository management

### ✅ Monitoring & Observability
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Data visualization and dashboards

## 🏗️ Architecture

The infrastructure consists of multiple EC2 instances:
- **ansible**: Management server with Ansible installed and configured
- **jenkins-master**: Jenkins master server
- **jenkins-slave**: Jenkins slave/agent server
- **sonarqube**: Code quality analysis server
- **jfrog**: Artifactory repository server
- **kubernetes-master**: Kubernetes control plane
- **kubernetes-worker**: Kubernetes worker nodes
- **monitoring**: Prometheus and Grafana server

## 📁 Project Structure

```
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Main Terraform configuration
│   ├── outputs.tf            # Outputs and connection info
│   ├── variables.tf          # Variable definitions
│   └── private-key/          # SSH keys
├── ansible/                  # Configuration Management
│   ├── playbooks/           # Ansible playbooks for each tool
│   ├── roles/               # Reusable Ansible roles
│   └── inventory/           # Dynamic inventory
├── kubernetes/              # Kubernetes configurations
│   ├── manifests/          # K8s resource definitions
│   └── helm-charts/        # Helm charts
├── docker/                 # Docker configurations
│   ├── images/            # Custom Docker images
│   └── docker-compose/    # Multi-container setups
├── jenkins/               # Jenkins configurations
│   ├── jobs/             # Jenkins job definitions
│   ├── pipelines/        # Jenkinsfile templates
│   └── plugins/          # Plugin configurations
├── monitoring/           # Monitoring stack
│   ├── prometheus/       # Prometheus configurations
│   └── grafana/          # Grafana dashboards
├── maven/               # Maven configurations
│   └── settings.xml     # Maven settings
└── scripts/             # Utility scripts
```

## 🚀 Quick Start

### Prerequisites
- Terraform installed
- AWS CLI configured
- SSH key pair in `terraform/private-key/`

### Deployment

1. **Navigate to Terraform directory**:
   ```bash
   cd terraform
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Apply the infrastructure**:
   ```bash
   terraform apply
   ```

## 🎯 Tool-Specific Setup

### GitHub Integration
- Webhook configurations for Jenkins
- Repository access setup
- Branch protection rules

### Jenkins Setup
- Master-slave architecture
- Pipeline configurations
- Plugin management
- Security configurations

### Maven Configuration
- Repository settings
- Build profiles
- Dependency management

### SonarQube
- Quality gate configurations
- Project analysis setup
- Integration with Jenkins

### JFrog Artifactory
- Repository configurations
- Access control
- Integration with Maven and Docker

### Docker & Kubernetes
- Container registry setup
- Kubernetes cluster configuration
- Helm chart deployment

### Monitoring Stack
- Prometheus metrics collection
- Grafana dashboards
- Alert configurations

## 📊 Monitoring & Observability

### Prometheus
- System metrics collection
- Application metrics
- Custom exporters

### Grafana
- Pre-configured dashboards
- Alert rules
- Data source configurations

## 🔧 Configuration Management

### Ansible Playbooks
- Automated tool installation
- Configuration management
- Health checks and monitoring

### Dynamic Inventory
- Automatic host discovery
- Group-based configurations
- Environment-specific settings

## 🛡️ Security

- SSH key management
- Security group configurations
- Access control policies
- Network segmentation

## 📈 Benefits

1. **Complete DevOps Toolchain**: All essential tools in one setup
2. **Infrastructure as Code**: Reproducible and version-controlled
3. **Automated Configuration**: Zero manual configuration required
4. **Scalable Architecture**: Easy to extend and modify
5. **Monitoring Integration**: Built-in observability
6. **Security Best Practices**: Secure by design

## 🧹 Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## 📚 Documentation

Each tool has its own documentation in its respective directory:
- [Terraform Documentation](./terraform/README.md)
- [Ansible Documentation](./ansible/README.md)
- [Kubernetes Documentation](./kubernetes/README.md)
- [Jenkins Documentation](./jenkins/README.md)
- [Monitoring Documentation](./monitoring/README.md)

## 🔄 Next Steps

With this foundation, you can:
1. Deploy applications using the CI/CD pipeline
2. Set up custom monitoring dashboards
3. Implement security scanning
4. Create custom Helm charts
5. Configure backup and disaster recovery
6. Add more tools to the stack

## 🆘 Troubleshooting

See individual tool documentation for specific troubleshooting guides, or check the [Troubleshooting Guide](./docs/troubleshooting.md) for common issues.

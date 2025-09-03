# Getting Started with DevOps Stack

This guide will help you set up and get started with the complete DevOps infrastructure.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (version 20.10 or later)
- **Docker Compose** (version 2.0 or later)
- **Git** (for version control)
- **curl** and **wget** (for downloading files)
- **OpenSSL** (for SSL certificate generation)

### System Requirements

- **CPU**: Minimum 4 cores (8+ recommended)
- **RAM**: Minimum 8GB (16GB+ recommended)
- **Storage**: Minimum 50GB free space
- **OS**: Linux (Ubuntu 20.04+ recommended), macOS, or Windows with WSL2

## Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd devops_projects-2
```

### 2. Run the Setup Script

```bash
chmod +x scripts/setup-devops.sh
./scripts/setup-devops.sh
```

This script will:
- Create the project directory structure
- Set up Docker networks and pull images
- Generate SSL certificates
- Create configuration files
- Start all services
- Display access information

### 3. Access the Services

Once the setup is complete, you can access the following services:

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Jenkins | http://localhost:8080 | admin / admin123 |
| SonarQube | http://localhost:9000 | admin / admin123 |
| JFrog Artifactory | http://localhost:8081/artifactory | admin / admin123 |
| Grafana | http://localhost:3000 | admin / admin123 |
| Prometheus | http://localhost:9090 | - |
| GitLab | http://localhost:8929 | root / root123 |
| Elasticsearch | http://localhost:9200 | - |
| Kibana | http://localhost:5601 | - |
| RabbitMQ | http://localhost:15672 | devops / devops123 |

## Manual Setup (Alternative)

If you prefer to set up components manually, follow these steps:

### 1. Infrastructure Setup (Terraform)

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Configuration Management (Ansible)

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/main.yml
```

### 3. Container Orchestration (Kubernetes)

```bash
cd kubernetes
kubectl apply -f manifests/
helm install app helm-charts/app/
```

## Configuration

### Environment Variables

The setup script creates a `.env` file with all necessary environment variables. You can customize these values:

```bash
# Edit the environment file
nano .env
```

Key variables to consider:
- `ADMIN_PASSWORD`: Change the default admin password
- `DOMAIN`: Set your domain name
- `BACKUP_RETENTION_DAYS`: Configure backup retention
- `PROMETHEUS_RETENTION_DAYS`: Configure metrics retention

### SSL Certificates

For production use, replace the self-signed certificates with proper SSL certificates:

```bash
# Replace SSL certificates
cp your-cert.crt ssl/server.crt
cp your-key.key ssl/server.key
```

### Security Configuration

1. **Change Default Passwords**: Update all default passwords
2. **Configure Firewall**: Set up proper firewall rules
3. **Enable HTTPS**: Configure SSL/TLS for all services
4. **Set up Authentication**: Configure LDAP or OAuth

## Service Configuration

### Jenkins

1. **Initial Setup**:
   - Access Jenkins at http://localhost:8080
   - Complete the initial setup wizard
   - Install recommended plugins

2. **Configure Credentials**:
   - Go to Manage Jenkins > Manage Credentials
   - Add SSH keys, API tokens, and passwords

3. **Set up Pipeline**:
   - Create a new pipeline job
   - Use the provided Jenkinsfile template

### SonarQube

1. **Quality Gates**:
   - Access SonarQube at http://localhost:9000
   - Configure quality gates for your projects
   - Set up code coverage thresholds

2. **Project Analysis**:
   - Create a new project
   - Generate analysis token
   - Configure build integration

### JFrog Artifactory

1. **Repository Setup**:
   - Access Artifactory at http://localhost:8081/artifactory
   - Create Maven, Docker, and NPM repositories
   - Configure permissions and access control

2. **Integration**:
   - Configure Maven settings.xml
   - Set up Docker registry
   - Configure CI/CD integration

### Grafana

1. **Data Sources**:
   - Access Grafana at http://localhost:3000
   - Add Prometheus as data source
   - Configure other data sources as needed

2. **Dashboards**:
   - Import provided dashboard templates
   - Create custom dashboards
   - Set up alerts and notifications

### Prometheus

1. **Target Configuration**:
   - Edit `monitoring/prometheus/prometheus.yml`
   - Add your application targets
   - Configure scrape intervals

2. **Alert Rules**:
   - Create alert rules in `monitoring/prometheus/rules/`
   - Configure Alertmanager
   - Set up notification channels

## Monitoring and Observability

### Health Checks

Run health checks to verify all services are working:

```bash
./scripts/health-check.sh
```

### Logs

View service logs:

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs jenkins
docker-compose logs sonarqube
docker-compose logs grafana
```

### Metrics

Access metrics endpoints:
- Prometheus: http://localhost:9090/metrics
- Node Exporter: http://localhost:9100/metrics
- cAdvisor: http://localhost:8080/metrics

## Backup and Recovery

### Automated Backups

The setup includes automated backup scripts:

```bash
# Manual backup
./scripts/backup.sh

# Schedule daily backups (already configured)
crontab -l
```

### Backup Locations

Backups are stored in:
- `/opt/backups/` (on the server)
- `./backups/` (in the project directory)

### Recovery

To restore from backup:

```bash
# Restore Jenkins
docker exec -i jenkins tar xzf - < backups/jenkins_YYYYMMDD_HHMMSS.tar.gz

# Restore PostgreSQL
docker exec -i postgres psql -U devops < backups/postgres_YYYYMMDD_HHMMSS.sql
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**:
   ```bash
   # Check what's using a port
   sudo netstat -tulpn | grep :8080
   
   # Stop conflicting service
   sudo systemctl stop conflicting-service
   ```

2. **Docker Issues**:
   ```bash
   # Restart Docker
   sudo systemctl restart docker
   
   # Clean up Docker
   docker system prune -a
   ```

3. **Service Won't Start**:
   ```bash
   # Check service logs
   docker-compose logs service-name
   
   # Check service status
   docker-compose ps
   ```

### Performance Issues

1. **Resource Limits**:
   - Increase Docker memory limits
   - Add more CPU cores
   - Optimize storage (use SSD)

2. **Network Issues**:
   - Check Docker network configuration
   - Verify firewall settings
   - Test connectivity between services

### Security Issues

1. **Authentication Problems**:
   - Verify credentials in `.env` file
   - Check service-specific authentication
   - Review access logs

2. **SSL/TLS Issues**:
   - Verify certificate validity
   - Check certificate paths
   - Test SSL configuration

## Next Steps

After successful setup:

1. **Configure CI/CD Pipelines**:
   - Set up Jenkins pipelines
   - Configure webhooks
   - Create deployment strategies

2. **Set up Monitoring**:
   - Import Grafana dashboards
   - Configure alerts
   - Set up log aggregation

3. **Security Hardening**:
   - Change default passwords
   - Configure SSL certificates
   - Set up access controls

4. **Production Deployment**:
   - Use proper SSL certificates
   - Configure backup strategies
   - Set up monitoring and alerting

## Support

For additional help:

- Check the logs in `./logs/`
- Review service-specific documentation
- Consult the troubleshooting guide
- Open an issue in the project repository

## Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.


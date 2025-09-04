#!/bin/bash

# DevOps Stack Setup Script
# This script sets up a complete DevOps infrastructure with all tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="devops-stack"
DOMAIN="example.com"
ADMIN_EMAIL="admin@${DOMAIN}"
ADMIN_PASSWORD="admin123"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
    fi
    
    # Check required commands
    local required_commands=("docker" "docker-compose" "git" "curl" "wget" "unzip")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "$cmd is required but not installed"
        fi
    done
    
    # Check Docker daemon
    if ! docker info &> /dev/null && ! sudo docker info &> /dev/null; then
        error "Docker daemon is not running"
    fi
    
    log "Prerequisites check passed"
}

# Create project structure
create_project_structure() {
    log "Creating project structure..."
    
    local directories=(
        "ansible/playbooks"
        "ansible/roles"
        "ansible/inventory"
        "kubernetes/manifests"
        "kubernetes/helm-charts"
        "docker/images"
        "docker/docker-compose"
        "jenkins/jobs"
        "jenkins/pipelines"
        "jenkins/plugins"
        "monitoring/prometheus"
        "monitoring/grafana"
        "maven"
        "scripts"
        "docs"
        "logs"
        "backups"
        "ssl"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        log "Created directory: $dir"
    done
}

# Setup Docker environment
setup_docker() {
    log "Setting up Docker environment..."
    
    # Create Docker networks
    docker network create jenkins-network 2>/dev/null || warn "jenkins-network already exists"
    docker network create monitoring-network 2>/dev/null || warn "monitoring-network already exists"
    docker network create kubernetes-network 2>/dev/null || warn "kubernetes-network already exists"
    
    # Pull base images
    log "Pulling base Docker images..."
    local images=(
        "jenkins/jenkins:lts-jdk17"
        "sonarqube:10.2.1-community"
        "sonatype/nexus3:latest"
        "prom/prometheus:v2.47.0"
        "grafana/grafana:10.1.5"
        "postgres:15-alpine"
        "redis:7-alpine"
        "nginx:alpine"
        "gitlab/gitlab-ce:16.5.0-ce.0"
        "elasticsearch:8.11.0"
        "kibana:8.11.0"
        "rabbitmq:3-management"
        "mongo:6.0"
        "minio/minio:RELEASE.2023-11-15T20-43-25Z"
    )
    
    for image in "${images[@]}"; do
        log "Pulling $image"
        docker pull "$image" || warn "Failed to pull $image"
    done
}

# Setup SSL certificates
setup_ssl() {
    log "Setting up SSL certificates..."
    
    # Create self-signed certificates for development
    if [[ ! -f "ssl/ca.key" ]]; then
        mkdir -p ssl
        openssl genrsa -out ssl/ca.key 4096
        openssl req -new -x509 -days 365 -key ssl/ca.key -out ssl/ca.crt -subj "/C=US/ST=State/L=City/O=Organization/CN=DevOps CA"
        
        # Generate server certificate
        openssl genrsa -out ssl/server.key 2048
        openssl req -new -key ssl/server.key -out ssl/server.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=*.${DOMAIN}"
        openssl x509 -req -days 365 -in ssl/server.csr -CA ssl/ca.crt -CAkey ssl/ca.key -CAcreateserial -out ssl/server.crt
        
        log "SSL certificates generated"
    else
        log "SSL certificates already exist"
    fi
}

# Setup environment variables
setup_environment() {
    log "Setting up environment variables..."
    
    cat > .env << EOF
# DevOps Stack Environment Variables
PROJECT_NAME=${PROJECT_NAME}
DOMAIN=${DOMAIN}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# Database Configuration
POSTGRES_DB=devops
POSTGRES_USER=devops
POSTGRES_PASSWORD=devops123
REDIS_PASSWORD=redis123

# Jenkins Configuration
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=${ADMIN_PASSWORD}

# SonarQube Configuration
SONARQUBE_ADMIN_USER=admin
SONARQUBE_ADMIN_PASSWORD=${ADMIN_PASSWORD}

# JFrog Artifactory Configuration
ARTIFACTORY_ADMIN_USER=admin
ARTIFACTORY_ADMIN_PASSWORD=${ADMIN_PASSWORD}

# Grafana Configuration
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=${ADMIN_PASSWORD}

# Prometheus Configuration
PROMETHEUS_RETENTION_DAYS=15

# Kubernetes Configuration
KUBERNETES_NAMESPACE=devops-demo
KUBERNETES_CLUSTER=devops-cluster

# Monitoring Configuration
ALERT_EMAIL=${ADMIN_EMAIL}
SLACK_WEBHOOK_URL=

# Backup Configuration
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE="0 2 * * *"

# Security Configuration
SECURITY_SCAN_ENABLED=true
VULNERABILITY_SCAN_ENABLED=true
EOF
    
    log "Environment file created: .env"
}

# Setup Docker Compose
setup_docker_compose() {
    log "Setting up Docker Compose..."
    
    # Copy the main docker-compose file
    cp docker/docker-compose/devops-stack.yml docker-compose.yml
    
    # Create development override
    cat > docker-compose.override.yml << EOF
services:
  # Development overrides
  jenkins:
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000
    volumes:
      - ./jenkins/jobs:/var/jenkins_jobs
      - ./jenkins/pipelines:/var/jenkins_pipelines
      - ./jenkins/plugins:/var/jenkins_plugins

  sonarqube:
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
      - SONAR_WEB_JAVAOPTS=-Xmx512m -Xms128m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError

  nexus:
    environment:
      - INSTALL4J_ADD_VM_PARAMS=-Xms512m -Xmx512m -XX:MaxDirectMemorySize=273m
      - NEXUS_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD}
      - NEXUS_SECURITY_RANDOMPASSWORD=false

  grafana:
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning

  prometheus:
    volumes:
      - ./monitoring/prometheus:/etc/prometheus
      - ./monitoring/prometheus/rules:/etc/prometheus/rules
EOF
    
    log "Docker Compose files created"
}

# Setup monitoring configuration
setup_monitoring() {
    log "Setting up monitoring configuration..."
    
    # Prometheus configuration
    cat > monitoring/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'jenkins'
    static_configs:
      - targets: ['jenkins:8080']
    metrics_path: /prometheus

  - job_name: 'sonarqube'
    static_configs:
      - targets: ['sonarqube:9000']
    metrics_path: /api/metrics

  - job_name: 'nexus'
    static_configs:
      - targets: ['nexus:8081']
    metrics_path: /service/metrics/prometheus
EOF
    
    # Grafana datasources
    mkdir -p monitoring/grafana/provisioning/datasources
    cat > monitoring/grafana/provisioning/datasources/datasources.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true

  - name: Jenkins
    type: prometheus
    access: proxy
    url: http://jenkins:8080/prometheus

  - name: SonarQube
    type: prometheus
    access: proxy
    url: http://sonarqube:9000/api/metrics
EOF
    
    # Grafana dashboards
    mkdir -p monitoring/grafana/provisioning/dashboards
    cat > monitoring/grafana/provisioning/dashboards/dashboards.yml << EOF
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF
    
    log "Monitoring configuration created"
}

# Setup Ansible configuration
setup_ansible() {
    log "Setting up Ansible configuration..."
    
    # Create ansible.cfg
    cat > ansible/ansible.cfg << EOF
[defaults]
inventory = inventory/hosts
host_key_checking = False
remote_user = devops
private_key_file = ~/.ssh/id_rsa
timeout = 30
gathering = smart
fact_caching = memory
stdout_callback = yaml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
pipelining = True
EOF
    
    # Create inventory
    cat > ansible/inventory/hosts << EOF
[all:vars]
ansible_user=devops
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

[jenkins-master]
jenkins-master ansible_host=localhost

[jenkins-slave]
jenkins-slave ansible_host=localhost

[sonarqube]
sonarqube ansible_host=localhost

[nexus]
nexus ansible_host=localhost

[kubernetes-master]
kubernetes-master ansible_host=localhost

[kubernetes-worker]
kubernetes-worker ansible_host=localhost

[monitoring]
monitoring ansible_host=localhost

[devops:children]
jenkins-master
jenkins-slave
sonarqube
nexus
kubernetes-master
kubernetes-worker
monitoring
EOF
    
    log "Ansible configuration created"
}

# Setup Kubernetes configuration
setup_kubernetes() {
    log "Setting up Kubernetes configuration..."
    
    # Create namespace
    cat > kubernetes/manifests/namespace.yml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: devops-demo
  labels:
    name: devops-demo
EOF
    
    # Create ConfigMap for application configuration
    cat > kubernetes/manifests/configmap.yml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: devops-demo
data:
  application.yml: |
    spring:
      application:
        name: app
      profiles:
        active: kubernetes
      datasource:
        url: jdbc:postgresql://postgres:5432/devops
        username: devops
        password: devops123
    management:
      endpoints:
        web:
          exposure:
            include: health,info,metrics,prometheus
EOF
    
    log "Kubernetes configuration created"
}

# Setup backup scripts
setup_backup() {
    log "Setting up backup scripts..."
    
    cat > scripts/backup.sh << 'EOF'
#!/bin/bash

# Backup script for DevOps stack
set -e

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup Jenkins
log "Backing up Jenkins..."
docker exec jenkins tar czf - /var/jenkins_home > "$BACKUP_DIR/jenkins_$DATE.tar.gz"

# Backup SonarQube
log "Backing up SonarQube..."
docker exec sonarqube tar czf - /opt/sonarqube/data > "$BACKUP_DIR/sonarqube_$DATE.tar.gz"

# Backup Nexus
log "Backing up Nexus..."
docker exec nexus tar czf - /nexus-data > "$BACKUP_DIR/nexus_$DATE.tar.gz"

# Backup PostgreSQL
log "Backing up PostgreSQL..."
docker exec postgres pg_dumpall -U devops > "$BACKUP_DIR/postgres_$DATE.sql"

# Backup Redis
log "Backing up Redis..."
docker exec redis redis-cli SAVE
docker exec redis tar czf - /data > "$BACKUP_DIR/redis_$DATE.tar.gz"

# Backup Prometheus
log "Backing up Prometheus..."
docker exec prometheus tar czf - /prometheus > "$BACKUP_DIR/prometheus_$DATE.tar.gz"

# Backup Grafana
log "Backing up Grafana..."
docker exec grafana tar czf - /var/lib/grafana > "$BACKUP_DIR/grafana_$DATE.tar.gz"

# Cleanup old backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.sql" -mtime +$RETENTION_DAYS -delete

log "Backup completed successfully"
EOF
    
    chmod +x scripts/backup.sh
    
    log "Backup scripts created"
}

# Setup health check scripts
setup_health_checks() {
    log "Setting up health check scripts..."
    
    cat > scripts/health-check.sh << 'EOF'
#!/bin/bash

# Health check script for DevOps stack
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check Jenkins
if curl -f http://localhost:8080 > /dev/null 2>&1; then
    log "Jenkins: OK"
else
    log "Jenkins: FAILED"
    exit 1
fi

# Check SonarQube
if curl -f http://localhost:9000 > /dev/null 2>&1; then
    log "SonarQube: OK"
else
    log "SonarQube: FAILED"
    exit 1
fi

# Check Nexus
if curl -f http://localhost:8081/artifactory > /dev/null 2>&1; then
    log "Nexus: OK"
else
    log "Nexus: FAILED"
    exit 1
fi

# Check Grafana
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    log "Grafana: OK"
else
    log "Grafana: FAILED"
    exit 1
fi

# Check Prometheus
if curl -f http://localhost:9090 > /dev/null 2>&1; then
    log "Prometheus: OK"
else
    log "Prometheus: FAILED"
    exit 1
fi

log "All services are healthy"
EOF
    
    chmod +x scripts/health-check.sh
    
    log "Health check scripts created"
}

# Start services
start_services() {
    log "Starting DevOps stack services..."
    
    # Start with Docker Compose
    docker-compose up -d
    
    log "Services started. Waiting for them to be ready..."
    
    # Wait for services to be ready
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if scripts/health-check.sh > /dev/null 2>&1; then
            log "All services are ready!"
            break
        fi
        
        log "Waiting for services to be ready... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        error "Services failed to start within expected time"
    fi
}

# Display access information
display_access_info() {
    log "DevOps Stack Setup Complete!"
    echo
    echo "Access Information:"
    echo "=================="
    echo "Jenkins:          http://localhost:8080"
    echo "SonarQube:        http://localhost:9000"
    echo "Nexus:            http://localhost:8081/artifactory"
    echo "Grafana:          http://localhost:3000"
    echo "Prometheus:       http://localhost:9090"
    echo "PostgreSQL:       localhost:5432"
    echo "Redis:            localhost:6379"
    echo "GitLab:           http://localhost:8929"
    echo "Elasticsearch:    http://localhost:9200"
    echo "Kibana:           http://localhost:5601"
    echo "RabbitMQ:         http://localhost:15672"
    echo "MongoDB:          localhost:27017"
    echo "MinIO:            http://localhost:9000"
    echo
    echo "Default Credentials:"
    echo "==================="
    echo "Username: admin"
    echo "Password: $ADMIN_PASSWORD"
    echo
    echo "Next Steps:"
    echo "==========="
    echo "1. Access Jenkins and complete initial setup"
    echo "2. Configure SonarQube quality gates"
    echo "3. Set up Nexus repositories"
    echo "4. Import Grafana dashboards"
    echo "5. Configure monitoring alerts"
    echo "6. Set up CI/CD pipelines"
    echo
    echo "Documentation: ./docs/"
    echo "Scripts: ./scripts/"
    echo "Logs: ./logs/"
}

# Main execution
main() {
    log "Starting DevOps Stack Setup..."
    
    check_prerequisites
    create_project_structure
    setup_docker
    setup_ssl
    setup_environment
    setup_docker_compose
    setup_monitoring
    setup_ansible
    setup_kubernetes
    setup_backup
    setup_health_checks
    start_services
    display_access_info
    
    log "DevOps Stack setup completed successfully!"
}

# Run main function
main "$@"


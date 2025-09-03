# Troubleshooting Guide

This guide provides solutions for common issues you may encounter when setting up and running the DevOps stack.

## Table of Contents

- [General Issues](#general-issues)
- [Docker Issues](#docker-issues)
- [Jenkins Issues](#jenkins-issues)
- [SonarQube Issues](#sonarqube-issues)
- [JFrog Artifactory Issues](#jfrog-artifactory-issues)
- [Grafana Issues](#grafana-issues)
- [Prometheus Issues](#prometheus-issues)
- [Kubernetes Issues](#kubernetes-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)
- [Security Issues](#security-issues)

## General Issues

### Services Not Starting

**Problem**: Services fail to start or remain in a restarting state.

**Solutions**:

1. **Check Docker daemon**:
   ```bash
   sudo systemctl status docker
   sudo systemctl start docker
   ```

2. **Check available resources**:
   ```bash
   # Check disk space
   df -h
   
   # Check memory
   free -h
   
   # Check CPU usage
   top
   ```

3. **Check service logs**:
   ```bash
   docker-compose logs [service-name]
   docker logs [container-name]
   ```

4. **Restart all services**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Port Conflicts

**Problem**: Services fail to start due to port conflicts.

**Solutions**:

1. **Check what's using the port**:
   ```bash
   sudo netstat -tulpn | grep :8080
   sudo lsof -i :8080
   ```

2. **Stop conflicting services**:
   ```bash
   sudo systemctl stop [service-name]
   ```

3. **Change port in docker-compose.yml**:
   ```yaml
   services:
     jenkins:
       ports:
         - "8081:8080"  # Change from 8080 to 8081
   ```

### Permission Issues

**Problem**: Permission denied errors when accessing files or directories.

**Solutions**:

1. **Fix file permissions**:
   ```bash
   sudo chown -R $USER:$USER .
   chmod +x scripts/*.sh
   ```

2. **Fix Docker socket permissions**:
   ```bash
   sudo usermod -aG docker $USER
   sudo chmod 666 /var/run/docker.sock
   ```

## Docker Issues

### Docker Daemon Not Running

**Problem**: Docker commands fail with "Cannot connect to the Docker daemon".

**Solutions**:

1. **Start Docker daemon**:
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. **Check Docker status**:
   ```bash
   sudo systemctl status docker
   ```

3. **Restart Docker**:
   ```bash
   sudo systemctl restart docker
   ```

### Container Won't Start

**Problem**: Containers exit immediately after starting.

**Solutions**:

1. **Check container logs**:
   ```bash
   docker logs [container-name]
   ```

2. **Run container interactively**:
   ```bash
   docker run -it [image-name] /bin/bash
   ```

3. **Check resource limits**:
   ```bash
   docker stats
   ```

### Image Pull Failures

**Problem**: Unable to pull Docker images.

**Solutions**:

1. **Check internet connectivity**:
   ```bash
   ping docker.io
   ```

2. **Configure Docker registry mirrors**:
   ```bash
   # Edit /etc/docker/daemon.json
   {
     "registry-mirrors": ["https://mirror.gcr.io"]
   }
   ```

3. **Use alternative registry**:
   ```bash
   docker pull mirror.gcr.io/library/[image-name]
   ```

## Jenkins Issues

### Jenkins Won't Start

**Problem**: Jenkins container fails to start or remains in a restarting state.

**Solutions**:

1. **Check Jenkins logs**:
   ```bash
   docker-compose logs jenkins
   ```

2. **Check Java memory settings**:
   ```yaml
   environment:
     - JAVA_OPTS=-Xmx2g -Xms1g
   ```

3. **Reset Jenkins home**:
   ```bash
   sudo rm -rf /var/lib/docker/volumes/[project-name]_jenkins_home
   ```

### Plugin Installation Failures

**Problem**: Jenkins plugins fail to install or update.

**Solutions**:

1. **Check Jenkins update center**:
   - Go to Manage Jenkins > Manage Plugins > Advanced
   - Verify update site URL

2. **Clear plugin cache**:
   ```bash
   docker exec jenkins rm -rf /var/jenkins_home/updates/
   ```

3. **Restart Jenkins**:
   ```bash
   docker-compose restart jenkins
   ```

### Pipeline Failures

**Problem**: Jenkins pipelines fail during execution.

**Solutions**:

1. **Check pipeline syntax**:
   - Use Jenkins Pipeline Syntax Validator
   - Check for syntax errors in Jenkinsfile

2. **Verify credentials**:
   - Go to Manage Jenkins > Manage Credentials
   - Ensure all required credentials are configured

3. **Check agent connectivity**:
   ```bash
   # Test SSH connection to agent
   ssh -i ~/.ssh/id_rsa devops@[agent-ip]
   ```

## SonarQube Issues

### SonarQube Won't Start

**Problem**: SonarQube container fails to start.

**Solutions**:

1. **Check system requirements**:
   ```bash
   # Ensure sufficient memory
   free -h
   
   # Check disk space
   df -h
   ```

2. **Disable Elasticsearch bootstrap checks**:
   ```yaml
   environment:
     - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
   ```

3. **Increase Java heap size**:
   ```yaml
   environment:
     - SONAR_WEB_JAVAOPTS=-Xmx2g -Xms1g
   ```

### Analysis Failures

**Problem**: SonarQube analysis fails or times out.

**Solutions**:

1. **Check project configuration**:
   - Verify sonar-project.properties
   - Check source and test directories

2. **Increase analysis timeout**:
   ```properties
   sonar.ce.timeoutInSeconds=3600
   ```

3. **Check quality gate configuration**:
   - Go to Administration > Quality Gates
   - Verify quality gate settings

## JFrog Artifactory Issues

### Artifactory Won't Start

**Problem**: JFrog Artifactory container fails to start.

**Solutions**:

1. **Check system requirements**:
   ```bash
   # Ensure sufficient memory (minimum 4GB)
   free -h
   ```

2. **Check Artifactory logs**:
   ```bash
   docker-compose logs jfrog
   ```

3. **Reset Artifactory data**:
   ```bash
   sudo rm -rf /var/lib/docker/volumes/[project-name]_artifactory_data
   ```

### Repository Access Issues

**Problem**: Unable to access or push to Artifactory repositories.

**Solutions**:

1. **Check repository permissions**:
   - Go to Administration > Security > Permissions
   - Verify user/group permissions

2. **Verify repository configuration**:
   - Check repository URLs
   - Verify authentication credentials

3. **Test connectivity**:
   ```bash
   curl -u admin:password http://localhost:8081/artifactory/api/system/ping
   ```

## Grafana Issues

### Grafana Won't Start

**Problem**: Grafana container fails to start.

**Solutions**:

1. **Check Grafana logs**:
   ```bash
   docker-compose logs grafana
   ```

2. **Reset Grafana data**:
   ```bash
   sudo rm -rf /var/lib/docker/volumes/[project-name]_grafana_data
   ```

3. **Check configuration**:
   ```bash
   docker exec grafana grafana-cli --version
   ```

### Data Source Connection Issues

**Problem**: Grafana cannot connect to data sources.

**Solutions**:

1. **Check data source URLs**:
   - Verify Prometheus URL: http://prometheus:9090
   - Check network connectivity between containers

2. **Test data source connectivity**:
   ```bash
   # Test Prometheus connection
   curl http://prometheus:9090/api/v1/query?query=up
   ```

3. **Check authentication**:
   - Verify credentials in data source configuration
   - Check for SSL/TLS issues

### Dashboard Issues

**Problem**: Dashboards not loading or showing no data.

**Solutions**:

1. **Check time range**:
   - Ensure time range includes data
   - Check for timezone issues

2. **Verify queries**:
   - Check PromQL queries
   - Verify metric names

3. **Check data availability**:
   ```bash
   # Check if metrics are being collected
   curl http://prometheus:9090/api/v1/label/__name__/values
   ```

## Prometheus Issues

### Prometheus Won't Start

**Problem**: Prometheus container fails to start.

**Solutions**:

1. **Check configuration syntax**:
   ```bash
   docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
   ```

2. **Check Prometheus logs**:
   ```bash
   docker-compose logs prometheus
   ```

3. **Verify configuration file**:
   ```bash
   # Check if configuration file exists
   ls -la monitoring/prometheus/prometheus.yml
   ```

### Target Scraping Issues

**Problem**: Prometheus cannot scrape targets.

**Solutions**:

1. **Check target status**:
   - Go to http://localhost:9090/targets
   - Look for failed targets

2. **Test target connectivity**:
   ```bash
   # Test target endpoint
   curl http://target:port/metrics
   ```

3. **Check network connectivity**:
   ```bash
   # Test from Prometheus container
   docker exec prometheus wget -qO- http://target:port/metrics
   ```

### Alert Issues

**Problem**: Alerts not firing or not being sent.

**Solutions**:

1. **Check alert rules**:
   ```bash
   # Validate alert rules
   docker exec prometheus promtool check rules /etc/prometheus/rules/*.yml
   ```

2. **Check Alertmanager**:
   ```bash
   # Check Alertmanager status
   curl http://alertmanager:9093/api/v1/status
   ```

3. **Verify notification configuration**:
   - Check Alertmanager configuration
   - Test notification channels

## Kubernetes Issues

### Cluster Won't Start

**Problem**: Kubernetes cluster fails to initialize.

**Solutions**:

1. **Check system requirements**:
   ```bash
   # Disable swap
   sudo swapoff -a
   
   # Load required modules
   sudo modprobe overlay
   sudo modprobe br_netfilter
   ```

2. **Reset cluster**:
   ```bash
   sudo kubeadm reset
   sudo kubeadm init
   ```

3. **Check kubelet status**:
   ```bash
   sudo systemctl status kubelet
   sudo journalctl -xeu kubelet
   ```

### Pod Issues

**Problem**: Pods fail to start or remain in pending state.

**Solutions**:

1. **Check pod events**:
   ```bash
   kubectl describe pod [pod-name] -n [namespace]
   ```

2. **Check node resources**:
   ```bash
   kubectl describe nodes
   kubectl top nodes
   ```

3. **Check image pull issues**:
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   ```

## Network Issues

### Container Communication Issues

**Problem**: Containers cannot communicate with each other.

**Solutions**:

1. **Check Docker networks**:
   ```bash
   docker network ls
   docker network inspect [network-name]
   ```

2. **Verify container network**:
   ```bash
   docker inspect [container-name] | grep -A 20 "NetworkSettings"
   ```

3. **Test connectivity**:
   ```bash
   # Test from one container to another
   docker exec [container1] ping [container2]
   ```

### DNS Resolution Issues

**Problem**: Containers cannot resolve hostnames.

**Solutions**:

1. **Check DNS configuration**:
   ```bash
   docker exec [container] cat /etc/resolv.conf
   ```

2. **Use container names**:
   - Use container names instead of IP addresses
   - Ensure containers are on the same network

3. **Add DNS servers**:
   ```yaml
   dns:
     - 8.8.8.8
     - 8.8.4.4
   ```

## Performance Issues

### High Resource Usage

**Problem**: Services consuming too much CPU or memory.

**Solutions**:

1. **Monitor resource usage**:
   ```bash
   docker stats
   htop
   ```

2. **Optimize resource limits**:
   ```yaml
   services:
     jenkins:
       deploy:
         resources:
           limits:
             cpus: '2.0'
             memory: 2G
           reservations:
             cpus: '1.0'
             memory: 1G
   ```

3. **Scale services**:
   ```bash
   docker-compose up -d --scale jenkins=2
   ```

### Slow Response Times

**Problem**: Services responding slowly.

**Solutions**:

1. **Check database performance**:
   ```bash
   # PostgreSQL
   docker exec postgres psql -U devops -c "SELECT * FROM pg_stat_activity;"
   
   # Redis
   docker exec redis redis-cli info memory
   ```

2. **Optimize storage**:
   - Use SSD storage
   - Configure proper volume mounts
   - Use tmpfs for temporary data

3. **Enable caching**:
   - Configure Redis caching
   - Enable application-level caching

## Security Issues

### Authentication Failures

**Problem**: Unable to authenticate to services.

**Solutions**:

1. **Check credentials**:
   ```bash
   # Verify environment variables
   cat .env | grep PASSWORD
   ```

2. **Reset passwords**:
   ```bash
   # Jenkins
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   
   # SonarQube
   # Access http://localhost:9000 and reset password
   ```

3. **Check user permissions**:
   - Verify user roles and permissions
   - Check group memberships

### SSL/TLS Issues

**Problem**: SSL certificate errors or HTTPS not working.

**Solutions**:

1. **Check certificate validity**:
   ```bash
   openssl x509 -in ssl/server.crt -text -noout
   ```

2. **Verify certificate paths**:
   ```bash
   ls -la ssl/
   ```

3. **Test SSL configuration**:
   ```bash
   openssl s_client -connect localhost:443 -servername localhost
   ```

### Access Control Issues

**Problem**: Unauthorized access or permission denied errors.

**Solutions**:

1. **Check firewall rules**:
   ```bash
   sudo ufw status
   sudo iptables -L
   ```

2. **Verify service permissions**:
   ```bash
   # Check file permissions
   ls -la /opt/
   
   # Check user permissions
   id devops
   ```

3. **Review access logs**:
   ```bash
   # Check service logs for access attempts
   docker-compose logs | grep -i "access\|auth\|login"
   ```

## Getting Help

If you're still experiencing issues:

1. **Check the logs**:
   ```bash
   docker-compose logs > logs.txt
   ```

2. **Collect system information**:
   ```bash
   # System info
   uname -a
   docker version
   docker-compose version
   
   # Resource usage
   free -h
   df -h
   ```

3. **Create a minimal reproduction**:
   - Document the exact steps to reproduce the issue
   - Include relevant configuration files
   - Provide error messages and logs

4. **Search existing issues**:
   - Check the project's issue tracker
   - Search for similar problems online

5. **Ask for help**:
   - Open an issue with detailed information
   - Include system specifications and error logs
   - Describe what you've already tried


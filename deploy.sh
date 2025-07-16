#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    terraform init
    terraform plan
    
    read -p "Do you want to proceed with infrastructure deployment? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        print_warning "Infrastructure deployment cancelled"
        exit 0
    fi
    
    terraform apply -auto-approve
    
    # Generate Ansible inventory
    terraform output -raw ansible_inventory > ../ansible/inventory.ini
    
    # Generate machines.txt for reference
    terraform output -raw machines_txt > ../machines.txt
    
    cd ..
    
    print_success "Infrastructure deployed successfully"
}

# Wait for instances to be ready
wait_for_instances() {
    print_status "Waiting for instances to be ready..."
    
    # Extract jumpbox IP
    jumpbox_ip=$(cd terraform && terraform output -raw jumpbox_public_ip)
    
    # Wait for SSH connectivity
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_status "Attempt $attempt/$max_attempts: Testing SSH connectivity to jumpbox..."
        
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
               root@$jumpbox_ip "echo 'SSH connection successful'" &> /dev/null; then
            print_success "SSH connectivity established"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "Failed to establish SSH connectivity after $max_attempts attempts"
            exit 1
        fi
        
        sleep 10
        ((attempt++))
    done
    
    # Additional wait for cloud-init to complete
    print_status "Waiting for cloud-init to complete..."
    sleep 60
}

# Deploy Kubernetes cluster with Ansible
deploy_kubernetes() {
    print_status "Deploying Kubernetes cluster with Ansible..."
    
    cd ansible
    
    # Test ansible connectivity
    if ! ansible all -m ping &> /dev/null; then
        print_error "Ansible connectivity test failed"
        exit 1
    fi
    
    print_success "Ansible connectivity test passed"
    
    # Run the full playbook
    ansible-playbook site.yml
    
    cd ..
    
    print_success "Kubernetes cluster deployed successfully"
}

# Display cluster information
display_cluster_info() {
    print_status "Cluster deployment completed!"
    echo ""
    echo "=== Cluster Information ==="
    echo ""
    
    jumpbox_ip=$(cd terraform && terraform output -raw jumpbox_public_ip)
    server_ip=$(cd terraform && terraform output -raw server_private_ip)
    node_0_ip=$(cd terraform && terraform output -raw node_0_private_ip)
    node_1_ip=$(cd terraform && terraform output -raw node_1_private_ip)
    
    echo "Jumpbox (Administration): ssh root@$jumpbox_ip"
    echo "Server (Control Plane):   $server_ip"
    echo "Node-0 (Worker):          $node_0_ip"
    echo "Node-1 (Worker):          $node_1_ip"
    echo ""
    echo "To access the cluster:"
    echo "1. SSH to jumpbox: ssh root@$jumpbox_ip"
    echo "2. Use kubectl: kubectl get nodes"
    echo ""
    echo "To clean up: ./cleanup.sh"
    echo ""
    
    print_success "Happy Kubernetes learning!"
}

# Main execution
main() {
    print_status "Starting Kubernetes The Hard Way deployment on AWS"
    echo ""
    
    check_prerequisites
    deploy_infrastructure
    wait_for_instances
    deploy_kubernetes
    display_cluster_info
}

# Handle script interruption
cleanup_on_exit() {
    print_warning "Script interrupted. You may need to run cleanup.sh to remove any created resources."
    exit 1
}

trap cleanup_on_exit INT TERM

# Run main function
main "$@"
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

# Cleanup Kubernetes resources
cleanup_kubernetes() {
    print_status "Cleaning up Kubernetes resources..."
    
    if [ -f "ansible/inventory.ini" ]; then
        cd ansible
        
        # Try to connect and clean up gracefully
        if ansible jumpbox -m ping &> /dev/null; then
            print_status "Attempting graceful cleanup of Kubernetes resources..."
            
            # Stop services on all nodes
            ansible cluster -m systemd -a "name=kubelet state=stopped" &> /dev/null || true
            ansible cluster -m systemd -a "name=kube-proxy state=stopped" &> /dev/null || true
            ansible control_plane -m systemd -a "name=kube-apiserver state=stopped" &> /dev/null || true
            ansible control_plane -m systemd -a "name=kube-controller-manager state=stopped" &> /dev/null || true
            ansible control_plane -m systemd -a "name=kube-scheduler state=stopped" &> /dev/null || true
            ansible control_plane -m systemd -a "name=etcd state=stopped" &> /dev/null || true
            ansible workers -m systemd -a "name=containerd state=stopped" &> /dev/null || true
            
            print_success "Kubernetes services stopped"
        else
            print_warning "Cannot connect to instances for graceful cleanup"
        fi
        
        cd ..
    else
        print_warning "No Ansible inventory found, skipping Kubernetes cleanup"
    fi
}

# Cleanup infrastructure with Terraform
cleanup_infrastructure() {
    print_status "Cleaning up infrastructure with Terraform..."
    
    if [ -d "terraform" ] && [ -f "terraform/terraform.tfstate" ]; then
        cd terraform
        
        # Show what will be destroyed
        print_status "The following resources will be destroyed:"
        terraform plan -destroy
        echo ""
        
        read -p "Do you want to proceed with infrastructure cleanup? (y/N): " confirm
        if [[ $confirm != [yY] ]]; then
            print_warning "Infrastructure cleanup cancelled"
            cd ..
            return
        fi
        
        terraform destroy -auto-approve
        
        cd ..
        
        print_success "Infrastructure destroyed successfully"
    else
        print_warning "No Terraform state found, skipping infrastructure cleanup"
    fi
}

# Clean up local files
cleanup_local_files() {
    print_status "Cleaning up local files..."
    
    # Remove generated files
    rm -f ansible/inventory.ini
    rm -f machines.txt
    
    # Remove Terraform files (optional)
    read -p "Do you want to remove Terraform state and plan files? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        rm -rf terraform/.terraform
        rm -f terraform/terraform.tfstate*
        rm -f terraform/.terraform.lock.hcl
        print_success "Terraform files removed"
    fi
    
    print_success "Local files cleaned up"
}

# Force cleanup (skip confirmations)
force_cleanup() {
    print_warning "Force cleanup mode enabled - skipping confirmations"
    
    cleanup_kubernetes
    
    if [ -d "terraform" ] && [ -f "terraform/terraform.tfstate" ]; then
        cd terraform
        terraform destroy -auto-approve &> /dev/null || true
        cd ..
    fi
    
    cleanup_local_files
    
    print_success "Force cleanup completed"
}

# Display help
show_help() {
    echo "Kubernetes The Hard Way - Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --force    Force cleanup without confirmations"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "This script will:"
    echo "1. Stop Kubernetes services gracefully (if accessible)"
    echo "2. Destroy AWS infrastructure using Terraform"
    echo "3. Clean up local generated files"
    echo ""
}

# Main execution
main() {
    case "${1:-}" in
        -f|--force)
            force_cleanup
            ;;
        -h|--help)
            show_help
            ;;
        "")
            print_status "Starting cleanup of Kubernetes The Hard Way deployment"
            echo ""
            cleanup_kubernetes
            cleanup_infrastructure
            cleanup_local_files
            echo ""
            print_success "Cleanup completed successfully"
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Handle script interruption
cleanup_on_exit() {
    print_warning "Cleanup script interrupted"
    exit 1
}

trap cleanup_on_exit INT TERM

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed"
    exit 1
fi

# Run main function
main "$@"
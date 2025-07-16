# Kubernetes The Hard Way - Automated Deployment

This project provides automated deployment of the "Kubernetes The Hard Way" tutorial using Terraform and Ansible on AWS.

## Overview

The automation creates a complete Kubernetes cluster following the exact steps from the original tutorial:
- **Infrastructure**: Terraform provisions AWS VPC, EC2 instances, security groups
- **Configuration**: Ansible automates all manual setup steps
- **Result**: Fully functional Kubernetes cluster identical to manual setup

## Architecture

### Infrastructure (AWS)
- **VPC**: Custom VPC with public subnet
- **EC2 Instances**:
  - Jumpbox (t3.micro): Administration host
  - Server (t3.small): Control plane node
  - Node-0, Node-1 (t3.small): Worker nodes
- **Security Groups**: Configured for Kubernetes components
- **Networking**: Pod routing between worker nodes

### Software Versions
- Kubernetes: v1.32.3
- containerd: v2.1.0-beta.0
- etcd: v3.6.0-rc.3
- CNI plugins: v1.6.2

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0
4. **Ansible** >= 2.9

### AWS Permissions Required
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:AddRoleToInstanceProfile"
            ],
            "Resource": "*"
        }
    ]
}
```

## Quick Start

1. **Clone and navigate to the project**:
   ```bash
   cd k8s
   ```

2. **Deploy the cluster**:
   ```bash
   ./deploy.sh
   ```

3. **Access your cluster**:
   ```bash
   # SSH to jumpbox (IP will be displayed)
   ssh root@<jumpbox-ip>
   
   # Use kubectl
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

4. **Clean up when done**:
   ```bash
   ./cleanup.sh
   ```

## Manual Configuration

If you prefer to customize the deployment:

### 1. Configure Variables
Edit `terraform/variables.tf` to customize:
- AWS region
- Instance types
- Network CIDRs
- SSH access

### 2. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Run Ansible Playbooks
```bash
cd ../ansible
# Generate inventory from Terraform
terraform output -raw ansible_inventory > inventory.ini

# Run individual playbooks or all at once
ansible-playbook site.yml
```

## Project Structure

```
k8s/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Provider and data sources
│   ├── variables.tf          # Input variables
│   ├── networking.tf         # VPC, subnets, routing
│   ├── security_groups.tf    # Security groups
│   ├── instances.tf          # EC2 instances
│   ├── outputs.tf            # Output values
│   ├── templates/            # Template files
│   └── user_data/           # Instance initialization
├── ansible/                  # Configuration Management
│   ├── site.yml             # Main playbook
│   ├── ansible.cfg          # Ansible configuration
│   ├── group_vars/          # Variable definitions
│   ├── playbooks/           # Individual playbooks
│   └── templates/           # Template files
├── configs/                 # Original Kubernetes configs
├── units/                   # Systemd unit files
├── docs/                    # Original tutorial docs
├── deploy.sh               # Deployment script
├── cleanup.sh              # Cleanup script
└── README-AUTOMATION.md    # This file
```

## Playbook Breakdown

1. **00-prerequisites.yml**: System updates, kernel modules, directories
2. **01-jumpbox-setup.yml**: Download binaries, install kubectl
3. **02-cluster-prep.yml**: SSH keys, hostnames, /etc/hosts
4. **03-certificates.yml**: Generate all TLS certificates
5. **04-kubeconfigs.yml**: Create kubeconfig files
6. **05-encryption-config.yml**: Generate encryption config
6. **06-etcd.yml**: Bootstrap etcd cluster
7. **07-control-plane.yml**: Deploy API server, controller, scheduler
8. **08-workers.yml**: Configure kubelet, kube-proxy, containerd
9. **09-kubectl-config.yml**: Configure remote kubectl access
10. **10-smoke-test.yml**: Run verification tests

## Customization

### Network Configuration
- Modify VPC CIDR: `terraform/variables.tf`
- Pod network CIDRs: `terraform/variables.tf`
- Service CIDR: `ansible/group_vars/all.yml`

### Instance Types
Change in `terraform/instances.tf`:
```hcl
# For larger instances
instance_type = "t3.medium"  # instead of t3.small
```

### Kubernetes Versions
Update in `ansible/group_vars/all.yml`:
```yaml
kubernetes_version: v1.32.3
containerd_version: v2.1.0-beta.0
```

## Troubleshooting

### Common Issues

1. **SSH Connection Timeout**
   - Check security groups allow SSH from your IP
   - Verify AWS key pair configuration

2. **Ansible Connection Failed**
   - Ensure instances are fully initialized
   - Check `/var/log/cloud-init-output.log` on instances

3. **Certificate Errors**
   - Verify system time is synchronized
   - Check certificate CN and SAN fields

### Debug Commands
```bash
# Check instance status
cd terraform && terraform show

# Test Ansible connectivity
cd ansible && ansible all -m ping

# Check service status on nodes
ansible cluster -m systemd -a "name=kubelet"

# View logs
ssh root@<node-ip> journalctl -u kubelet -f
```

## Cost Estimation

Approximate AWS costs (us-west-2):
- 4 × t3.small instances: ~$0.08/hour
- 1 × t3.micro instance: ~$0.0104/hour
- EBS storage (80GB total): ~$0.32/hour
- **Total**: ~$0.41/hour or ~$10/day

## Learning Path

This automation preserves the educational value of the original tutorial:

1. **Study the Code**: Examine Terraform and Ansible configurations
2. **Manual Steps**: Try running individual playbooks
3. **Customization**: Modify configurations and redeploy
4. **Troubleshooting**: Intentionally break things and fix them
5. **Extension**: Add monitoring, logging, or additional nodes

## Security Considerations

⚠️ **This setup is for learning only, not production use!**

- Root SSH access enabled for simplicity
- Open security groups for cluster communication
- Self-signed certificates
- No network encryption between components

## Support

For issues with:
- **Original tutorial**: See [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- **This automation**: Check troubleshooting section or create an issue

## License

This automation follows the same Creative Commons license as the original tutorial.
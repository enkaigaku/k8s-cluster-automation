[jumpbox]
jumpbox ansible_host=${jumpbox_public_ip} ansible_user=root

[control_plane]
server ansible_host=${server_private_ip} ansible_user=root

[workers]
node-0 ansible_host=${node_0_private_ip} ansible_user=root pod_cidr=${pod_cidr_node_0}
node-1 ansible_host=${node_1_private_ip} ansible_user=root pod_cidr=${pod_cidr_node_1}

[cluster:children]
control_plane
workers

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
kubernetes_version=v1.32.3
containerd_version=v2.1.0-beta.0
etcd_version=v3.6.0-rc.3
cni_version=v1.6.2
crictl_version=v1.32.0
cluster_name=kubernetes
service_cidr=10.32.0.0/24
cluster_dns=10.32.0.10
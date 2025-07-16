# Security Group for Jumpbox
resource "aws_security_group" "jumpbox" {
  name_prefix = "${var.project_name}-jumpbox-"
  vpc_id      = aws_vpc.main.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-jumpbox-sg"
    Environment = var.environment
  }
}

# Security Group for Kubernetes Server (Control Plane)
resource "aws_security_group" "server" {
  name_prefix = "${var.project_name}-server-"
  vpc_id      = aws_vpc.main.id

  # SSH from jumpbox
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumpbox.id]
  }

  # Kubernetes API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # etcd client requests
  ingress {
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # etcd peer communication
  ingress {
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-server-sg"
    Environment = var.environment
  }
}

# Security Group for Worker Nodes
resource "aws_security_group" "worker" {
  name_prefix = "${var.project_name}-worker-"
  vpc_id      = aws_vpc.main.id

  # SSH from jumpbox
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumpbox.id]
  }

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NodePort Services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Pod-to-pod communication (all pods network CIDRs)
  dynamic "ingress" {
    for_each = var.pod_cidr_blocks
    content {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.pod_cidr_blocks
    content {
      from_port   = 0
      to_port     = 65535
      protocol    = "udp"
      cidr_blocks = [ingress.value]
    }
  }

  # ICMP for pod networking
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-worker-sg"
    Environment = var.environment
  }
}
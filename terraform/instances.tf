# Key pair
resource "aws_key_pair" "main" {
  count      = var.key_name == "" ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.main[0].public_key_openssh

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
  }
}

resource "tls_private_key" "main" {
  count     = var.key_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  key_name = var.key_name != "" ? var.key_name : aws_key_pair.main[0].key_name
}

# Jumpbox Instance
resource "aws_instance" "jumpbox" {
  ami                    = data.aws_ami.debian12.id
  instance_type          = "t3.micro"
  key_name               = local.key_name
  vpc_security_group_ids = [aws_security_group.jumpbox.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data/debian.sh", {
    hostname = "jumpbox"
  }))

  tags = {
    Name        = "${var.project_name}-jumpbox"
    Environment = var.environment
    Role        = "jumpbox"
  }
}

# Server Instance (Control Plane)
resource "aws_instance" "server" {
  ami                     = data.aws_ami.debian12.id
  instance_type           = "t3.small"
  key_name                = local.key_name
  vpc_security_group_ids  = [aws_security_group.server.id]
  subnet_id               = aws_subnet.public.id
  source_dest_check       = false
  private_ip              = cidrhost(var.public_subnet_cidr, 10)

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data/debian.sh", {
    hostname = "server"
  }))

  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
    Role        = "control-plane"
  }
}

# Worker Node 0
resource "aws_instance" "node_0" {
  ami                     = data.aws_ami.debian12.id
  instance_type           = "t3.small"
  key_name                = local.key_name
  vpc_security_group_ids  = [aws_security_group.worker.id]
  subnet_id               = aws_subnet.public.id
  source_dest_check       = false
  private_ip              = cidrhost(var.public_subnet_cidr, 20)

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data/debian.sh", {
    hostname = "node-0"
  }))

  tags = {
    Name        = "${var.project_name}-node-0"
    Environment = var.environment
    Role        = "worker"
    PodCIDR     = var.pod_cidr_blocks[0]
  }
}

# Worker Node 1
resource "aws_instance" "node_1" {
  ami                     = data.aws_ami.debian12.id
  instance_type           = "t3.small"
  key_name                = local.key_name
  vpc_security_group_ids  = [aws_security_group.worker.id]
  subnet_id               = aws_subnet.public.id
  source_dest_check       = false
  private_ip              = cidrhost(var.public_subnet_cidr, 21)

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data/debian.sh", {
    hostname = "node-1"
  }))

  tags = {
    Name        = "${var.project_name}-node-1"
    Environment = var.environment
    Role        = "worker"
    PodCIDR     = var.pod_cidr_blocks[1]
  }
}
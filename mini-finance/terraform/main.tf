data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ---------- Network ----------
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-${var.project_name}" }
}

resource "aws_subnet" "snet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "snet-${var.project_name}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "igw-${var.project_name}" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "rt-${var.project_name}" }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.snet.id
  route_table_id = aws_route_table.rt.id
}

# ---------- Security group (Azure NSG equivalent) ----------
resource "aws_security_group" "nsg" {
  name        = "nsg-${var.project_name}"
  description = "Mini Finance web server rules"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow-SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.controller_ip}/32"]
  }

  ingress {
    description = "Allow-HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "nsg-${var.project_name}" }
}

# ---------- NIC with the security group attached ----------
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.snet.id
  security_groups = [aws_security_group.nsg.id]
  tags            = { Name = "nic-${var.project_name}" }
}

# ---------- Public IP (Azure public IP equivalent) ----------
resource "aws_eip" "pip" {
  domain            = "vpc"
  network_interface = aws_network_interface.nic.id
  tags              = { Name = "pip-${var.project_name}" }

  depends_on = [aws_internet_gateway.igw]
}

# ---------- VM ----------
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_instance" "vm" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }

  user_data = <<-CLOUDINIT
    #cloud-config
    hostname: ${var.project_name}
  CLOUDINIT

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  tags = { Name = "vm-${var.project_name}" }
}

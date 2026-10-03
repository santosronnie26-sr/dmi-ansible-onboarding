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
resource "aws_vpc" "lab" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "ansible-lab-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "ansible-lab-public" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "ansible-lab-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "ansible-lab-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------- Security groups ----------
# SSH for every VM - controller IP only
resource "aws_security_group" "ssh" {
  name        = "ansible-lab-ssh"
  description = "SSH from Ansible controller only"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "SSH from controller"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.controller_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ansible-lab-ssh" }
}

# HTTP - attached to web hosts only
resource "aws_security_group" "web" {
  name        = "ansible-lab-web"
  description = "HTTP for web hosts only"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ansible-lab-web" }
}

# ---------- Compute ----------
resource "aws_key_pair" "controller" {
  key_name   = "ansible-controller-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_instance" "vm" {
  for_each = var.vm_roles

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.controller.key_name

  # web hosts get SSH + HTTP; app/db get SSH only
  vpc_security_group_ids = each.value == "web" ? [aws_security_group.ssh.id, aws_security_group.web.id] : [aws_security_group.ssh.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = each.key
    Role = each.value
  }
}

# Ansible Ad-Hoc Lab — Multi-Host on AWS

**Author:** Ronnie Santos
**Program:** DevOps Micro Internship (DMI) — Week 9, Assignment 02

## Summary

Terraform provisions four Ubuntu 22.04 VMs on AWS, grouped by role. Ansible then
manages them from the controller built in Assignment 01, using ad-hoc commands
against a custom inventory.

| Item     | Choice                                   |
|----------|------------------------------------------|
| Cloud    | AWS (`ap-southeast-1`)                   |
| VM count | Four-VM option                           |
| Roles    | web1, web2 (web) · app1 (app) · db1 (db) |
| Size     | t3.micro, 8 GB gp3                       |

## Layout

| Path                     | Purpose                                         |
|--------------------------|-------------------------------------------------|
| `terraform/providers.tf` | AWS provider, pinned profile, default tags      |
| `terraform/variables.tf` | Region, role map, instance type, controller IP  |
| `terraform/main.tf`      | VPC, subnet, IGW, security groups, 4 VMs        |
| `terraform/outputs.tf`   | Role → public/private IP maps                   |
| `ansible/inventory.ini`  | `web`, `app`, `db` groups                       |

## Security Design

- SSH (22) allowed only from the controller's public IP (`/32`).
- HTTP (80) attached only to web hosts through a separate security group.
- Key-based SSH using the controller's ED25519 key; the private key never leaves the controller.
- `terraform.tfvars` and state files are gitignored.

## Usage

    cd terraform
    echo 'controller_ip = "<your-public-ip>"' > terraform.tfvars
    terraform init && terraform apply

    # update ansible/inventory.ini with: terraform output public_ips
    cd ../ansible
    ansible all -i inventory.ini -m ping

    # cleanup
    cd ../terraform && terraform destroy

## Ad-Hoc Commands Run

    ansible all -i inventory.ini -m ping
    ansible all -i inventory.ini -m command -a "uptime"
    ansible web -i inventory.ini -m apt -a "name=nginx state=present update_cache=yes" --become
    ansible web -i inventory.ini -m service -a "name=nginx state=started enabled=yes" --become
    ansible all -i inventory.ini -m apt -a "name=htop state=present update_cache=yes" --become
    ansible web -i inventory.ini -m command -a "systemctl is-active nginx"

## Status

Infrastructure destroyed after evidence was captured. The IPs in `inventory.ini`
are from that run and no longer active.

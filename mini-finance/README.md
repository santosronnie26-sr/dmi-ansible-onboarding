# Mini Finance — Terraform + Ansible Deployment

**Author:** Ronnie Santos
**Program:** DevOps Micro Internship (DMI) — Week 9, Assignment 04

## Summary

Terraform provisions an Ubuntu VM and its network on AWS. A three-play Ansible
playbook then installs Nginx, deploys the Mini Finance static website from GitHub,
and verifies it returns HTTP 200 from the controller.

**Platform note:** The assignment is written for Azure. It was built on AWS (no
Azure credits available) using Azure-equivalent resource names.

## Responsibilities

| Tool      | Responsibility                                                    |
|-----------|-------------------------------------------------------------------|
| Terraform | Network, security rules, public IP, SSH key, and the VM            |
| Ansible   | Packages, Nginx service, website deployment, and verification      |

## Infrastructure (Terraform)

| Azure term     | AWS resource                 | Name                |
|----------------|------------------------------|---------------------|
| VNet           | VPC (10.0.0.0/16)            | `vpc-mini-finance`  |
| Subnet         | Subnet (10.0.1.0/24)         | `snet-mini-finance` |
| NSG            | Security group               | `nsg-mini-finance`  |
| NIC            | Network interface            | `nic-mini-finance`  |
| Public IP      | Elastic IP                   | `pip-mini-finance`  |
| VM             | EC2 t3.micro, Ubuntu 22.04   | `vm-mini-finance`   |

Security group rules:
- **Allow-SSH**: port 22 from the controller's public IP only (`/32`)
- **Allow-HTTP**: port 80 from anywhere

The security group is attached to the network interface, which is attached to the
VM as its primary interface. Cloud-init sets the hostname to `mini-finance`.

## Project Structure

    mini-finance/
    ├── .gitignore
    ├── README.md
    ├── terraform/
    │   ├── providers.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ansible/
        ├── inventory.ini
        └── site.yml

## Playbook (site.yml)

**Play 1 — Install and configure Nginx** (`hosts: web`)
Installs `nginx`, `git`, and `rsync`, then starts and enables Nginx.

**Play 2 — Deploy the Mini Finance website** (`hosts: web`)
Clones `https://github.com/pravinmishraaws/mini_finance.git` to `/opt/mini-finance`,
syncs it to `/var/www/html/` with `ansible.posix.synchronize` (excluding `.git`),
and sets ownership to `www-data:www-data`. A `Reload nginx` handler runs only when
the synced content changes.

**Play 3 — Verify the website** (`hosts: localhost`)
Sends an HTTP GET to the VM's public IP with the `uri` module and uses `assert`
to confirm HTTP 200.

## How to Run

    # Provision
    cd terraform
    echo 'controller_ip = "<your-public-ip>"' > terraform.tfvars
    terraform fmt && terraform init && terraform validate
    terraform plan
    terraform apply
    terraform output public_ip

    # Configure and deploy
    cd ../ansible
    ansible web -i inventory.ini -m ping
    ansible-playbook -i inventory.ini site.yml --syntax-check
    ansible-playbook -i inventory.ini site.yml

    # Clean up
    cd ../terraform && terraform destroy

## Results

- `terraform apply`: 10 resources added, no errors
- SSH returned the hostname `mini-finance` with no password
- Playbook recap: `mini-finance ok=8 changed=5`, `localhost ok=2`,
  `failed=0 unreachable=0`
- Play 3: HTTP 200 from `nginx/1.18.0`, 31,958 bytes (the Mini Finance `index.html`)
- Website loaded in the browser at the VM's public IP

## Lessons Learned

- Terraform and Ansible have clear, separate jobs: Terraform builds the server,
  Ansible configures what runs on it.
- On AWS, a pre-created network interface doesn't get an auto-assigned public IP,
  so an Elastic IP is needed to reach the VM.
- `synchronize` needs `delegate_to: "{{ inventory_hostname }}"` to copy between
  two folders on the same remote host instead of from the controller.
- Disabling owner/group preservation in `synchronize` keeps the ownership task
  idempotent.

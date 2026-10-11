# EpicBook — Terraform + Ansible Roles (AWS)

**Author:** Ronnie Santos
**Program:** DevOps Micro Internship (DMI) — Week 9, Assignment 05
**Cloud provider:** AWS (`ap-southeast-1`)

## Summary

Terraform provisions one Ubuntu VM and one private managed MySQL database (RDS).
Three Ansible roles then prepare the VM, configure Nginx as a reverse proxy, and
deploy the EpicBook Node.js app under PM2, connected to RDS.

    Browser -> Nginx :80 -> Node.js (EpicBook) :8080 -> RDS MySQL :3306 (private)

## Project Structure

    epicbook-prod/
    ├── .gitignore
    ├── README.md
    ├── terraform/aws/
    │   ├── providers.tf  main.tf  variables.tf  outputs.tf
    └── ansible/
        ├── ansible.cfg
        ├── inventory.ini
        ├── site.yml
        ├── group_vars/web.yml
        └── roles/
            ├── common/tasks/main.yml
            ├── nginx/{tasks,templates,handlers}/
            └── epicbook/{tasks,templates,handlers}/

## Infrastructure (Terraform — 13 resources)

| Area     | Resources                                                              |
|----------|------------------------------------------------------------------------|
| Network  | VPC 10.0.0.0/16, public subnet, 2 private subnets (2 AZs), IGW, route table |
| Security | `epicbook-ec2-sg`: SSH 22 from controller `/32`, HTTP 80 open          |
|          | `epicbook-rds-sg`: MySQL 3306 from the EC2 security group only         |
| Compute  | Key pair, EC2 `t3.micro` Ubuntu 22.04 (hostname `epicbook`)            |
| Database | DB subnet group, RDS MySQL 8.0 `db.t3.micro`, `publicly_accessible = false` |

Outputs: `ec2_public_ip`, `rds_endpoint`, `db_name`, `db_username`. No password output.

## Ansible Roles

| Order | Role       | Responsibility                                                       |
|-------|------------|----------------------------------------------------------------------|
| 1     | `common`   | apt cache, base packages, `mysql-client`, Node.js 20 (NodeSource)    |
| 2     | `nginx`    | Install Nginx, deploy reverse-proxy template, enable site, `nginx -t` |
| 3     | `epicbook` | Clone repo, `npm install`, one-time SQL import, PM2 ecosystem + start |

## Secrets Handling

- The DB password is generated randomly and stored only in the gitignored `terraform.tfvars`.
- In Ansible, it is Vault-encrypted inline in `group_vars/web.yml` (`ansible-vault encrypt_string`).
- Tasks using it run with `no_log: true` and pass it through `MYSQL_PWD`, not the command line.
- On the VM, it exists only in the PM2 ecosystem file (`0600`, owned by `ubuntu`).

## How to Run

    # Provision
    cd terraform/aws
    terraform init && terraform plan && terraform apply
    terraform output

    # Configure and deploy
    cd ../../ansible
    ansible web -i inventory.ini -m ping
    ansible-playbook -i inventory.ini site.yml --syntax-check
    ansible-playbook -i inventory.ini site.yml --ask-vault-pass

    # Clean up
    cd ../terraform/aws && terraform destroy

## Verification Results

| Check                           | Result                                     |
|---------------------------------|--------------------------------------------|
| Playbook recap                  | `failed=0`                                 |
| `systemctl is-active nginx`     | `active`                                   |
| `pm2 status`                    | `epicbook` online, user `ubuntu`           |
| `curl -I localhost:8080`        | `200 OK`, `X-Powered-By: Express`          |
| `curl -I http://<public_ip>`    | `200 OK` via Nginx, 24,858 bytes           |
| `POST /api/cart {"bookId": 1}`  | JSON cart row for "28 Summers" (RDS write) |
| `GET /cart`                     | `HTTP 200`                                 |
| Second playbook run             | `failed=0`, SQL import and PM2 start skipped |

## Issues and Fixes

1. **Empty PM2 template:** the ecosystem template was overwritten with an empty file, so
   PM2 failed with `No script path`. Syntax checks don't read templates; recreated the
   file and verified it with `cat`.
2. **Nginx served the default page:** the first run failed after queueing the Nginx
   reload handler, so the reload never ran. Reloaded Nginx manually and added
   `force_handlers: true` to `site.yml`.
3. **App ignores `.env`:** EpicBook reads `JAWSDB_URL` with `NODE_ENV=production`
   (`config/config.json`), so the connection is set in the PM2 ecosystem file.
4. **ansible-lint (production profile):** added explicit `become: true` beside
   `become_user`, `changed_when` on command tasks, and role-prefixed variable names.

## Production Improvements

HTTPS (Let's Encrypt or ALB + ACM), the DB password in AWS Secrets Manager, RDS
encryption and automated backups, the VM in a private subnet behind a load balancer
with a NAT Gateway, Session Manager instead of SSH, and `host_key_checking` re-enabled.

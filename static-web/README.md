# Static Website Deployment — Multi-Play Ansible Playbook

**Author:** Ronnie Santos
**Program:** DevOps Micro Internship (DMI) — Week 9, Assignment 03

## Summary

A single Ansible playbook (`site.yml`) installs Nginx on two Ubuntu web servers,
deploys a personalized static website to both, and checks from the controller
that each one returns HTTP 200. The work is split into three plays, each with one job.

## Environment

| Item       | Detail                                                     |
|------------|------------------------------------------------------------|
| Controller | WSL2 Ubuntu 22.04, Ansible in the project venv             |
| Servers    | 2 × AWS EC2 Ubuntu 22.04 (`web1`, `web2`), `ap-southeast-1` |
| Provisioned by | Terraform from `../ansible-adhoc-lab/terraform`        |
| Access     | Key-based SSH (ED25519); SSH limited to controller IP      |

## Project Structure

| Path               | Purpose                                         |
|--------------------|-------------------------------------------------|
| `inventory.ini`    | `web` group with web1 and web2, plus SSH vars   |
| `site.yml`         | Multi-play playbook                             |
| `files/index.html` | Website content, personalized with my name      |
| `README.md`        | This document                                   |

## How the Playbook Works

**Play 1 — Install and configure Nginx** (`hosts: web`, `become: true`)
Refreshes the APT cache, installs Nginx, then starts it and enables it on boot.

**Play 2 — Deploy the static website** (`hosts: web`, `become: true`)
Copies `files/index.html` to `/var/www/html/index.html`, owned by `www-data`
with mode `0644`. If the file changes, it notifies the `Reload nginx` handler.
If the file is already identical, the handler does not run.

**Play 3 — Verify from the controller** (`hosts: localhost`, `gather_facts: false`)
Loops over the `web` group, sends an HTTP GET to each server's `ansible_host`
with the `uri` module, then uses `assert` to confirm each returned HTTP 200.

## How to Run

    source ~/ansible-onboarding/.venv/bin/activate
    cd ~/ansible-onboarding/static-web

    ansible-inventory -i inventory.ini --graph
    ansible web -i inventory.ini -m ping
    ansible-playbook -i inventory.ini site.yml --syntax-check
    ansible-playbook -i inventory.ini site.yml

## Results

| Run | web1 / web2         | Handler | Play 3              |
|-----|---------------------|---------|---------------------|
| 1st | ok=7, changed=4     | Ran     | Both returned 200   |
| 2nd | ok=6, changed=1     | Skipped | Both returned 200   |

The first run installed Nginx, copied the site, and reloaded Nginx. The second
run changed only the APT cache refresh, which reports a change every time.
Install, start, and copy all reported `ok`, and the handler did not fire.
`curl -I` returned `HTTP/1.1 200 OK` from both servers, and the browser showed
the footer "Hosted By 2026 Ronnie Santos" on both IPs.

## What I Learned

- **Plays separate responsibilities.** Install, deploy, and verify each have
  their own play, so a failure points straight to the stage that broke.
- **Handlers prevent unnecessary restarts.** Nginx reloads only when the
  website file actually changes, not on every run.
- **Idempotency can be seen in the recap.** Going from `changed=4` to
  `changed=1` showed the playbook only acts when the server's state doesn't
  match what's declared.
- **Verify from outside the server.** Running the checks from `localhost`
  tests the real network path, including the security group, not just
  whether Nginx is running locally.
- **Accept host keys before parallel runs.** On first contact, Ansible's
  parallel connections produced overlapping fingerprint prompts. Accepting each
  host key with `ssh` first avoids this.

## Cleanup

The servers were destroyed with `terraform destroy` after evidence was captured.
The IPs in `inventory.ini` are no longer active.

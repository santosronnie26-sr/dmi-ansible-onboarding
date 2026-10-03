# Ansible Onboarding Workstation

**Author:** Ronnie Santos
**Program:** DevOps Micro Internship (DMI) Cohort 3 

## Project Summary

A team-ready Ansible controller workstation built on WSL2 Ubuntu. Ansible and its
tooling run inside an isolated Python virtual environment, VS Code is wired to that
environment, SSH is key-based, and every commit is checked by yamllint and
ansible-lint through pre-commit hooks. This workspace is the controller for the
upcoming Ansible assignments.

## Environment

| Component    | Version / Detail              |
|--------------|-------------------------------|
| Host OS      | Windows + WSL2 Ubuntu 22.04   |
| Python       | 3.10.12 (project `.venv`)     |
| ansible-core | 2.17.14                       |
| ansible-lint | 26.6.0                        |
| yamllint     | 1.38.0                        |
| pre-commit   | 4.6.2                         |
| Editor       | VS Code (WSL remote)          |

## Project Structure

| Path                      | Purpose                                         |
|---------------------------|-------------------------------------------------|
| `ansible.cfg`             | Project-level Ansible defaults                  |
| `inventories/`            | Host inventories                                |
| `roles/`                  | Ansible roles                                   |
| `requirements.txt`        | Pinned Python tooling versions                  |
| `.pre-commit-config.yaml` | yamllint + ansible-lint commit hooks            |
| `.yamllint`               | yamllint rules aligned with ansible-lint        |
| `.ansible-lint`           | Excludes `.venv/` and `.cache/` from linting    |
| `.vscode/settings.json`   | Points VS Code at the venv; enables linting     |
| `.editorconfig`           | Cross-editor formatting (2-space, LF, UTF-8)    |
| `.gitignore`              | Keeps `.venv/`, keys, and secrets out of Git    |

## Notes and Pitfalls

- Keep the project on the WSL filesystem (`~/`), not `/mnt/c/`. Ansible ignores
  `ansible.cfg` in world-writable directories, which Windows-mounted drives appear to be.
- The upstream ansible-lint pre-commit hook needs Python 3.11+. On Ubuntu 22.04
  (Python 3.10) it runs as a `local` hook from the project venv instead.
- Never commit private keys or `.venv/`. Both are covered by `.gitignore`.

## New Machine? Do This

1. Install WSL2 with Ubuntu 22.04 (`wsl --install -d Ubuntu-22.04`).
2. Install system packages: `sudo apt install -y git python3-venv python3-pip`.
3. Clone this repo into `~/` (never under `/mnt/c/`).
4. Create and activate the venv: `python3 -m venv .venv && source .venv/bin/activate`.
5. Install tooling: `pip install -r requirements.txt`.
6. Open the folder in VS Code via **WSL: Connect to WSL** and install the Ansible, YAML,
   Python, and EditorConfig extensions.
7. Select `./.venv/bin/python` as the Python interpreter.
8. Confirm `ansible --version` shows this repo's `ansible.cfg`.
9. Generate an SSH key: `ssh-keygen -t ed25519 -C "<name>-ansible-controller"`.
10. Load it: `eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519`, then add the
    `Host *` defaults to `~/.ssh/config`.
11. Set Git identity: `git config --global user.name`, `user.email`, and
    `init.defaultBranch main`.
12. Install hooks and smoke-test: `pre-commit install && pre-commit run --all-files`.

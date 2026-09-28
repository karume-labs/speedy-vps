# Speedy VPS Configuration

A lightning-fast, production-ready Ansible orchestration repository designed to bootstrap and secure new VPS instances (like Contabo, DigitalOcean, or Hetzner) in minutes.

This setup automatically splits your infrastructure into an Application Node and a Database Node. It supports a **Dual-Mode** deployment out of the box:
1. **Dockerized Mode**: Uses Traefik auto-routing and Docker Compose.
2. **Bare Metal Mode**: Directly installs Node.js, Bun, PM2, and Caddy (Zero-config SSL) for non-dockerized applications (e.g., standard Next.js apps).

Both modes include strict firewall rules, automated backups, and database lock-downs, perfectly mirroring a scalable web architecture.

---

## Features Included Out-of-the-Box

*   **Security First**: Disables root password SSH login, configures `ufw` firewalls, and sets up `fail2ban`.
*   **Stability**: Forces the `UTC` timezone, sets up automated `unattended-upgrades`, and automatically allocates a 2GB Swap file.
*   **Dual-Mode App Node**: 
    *   *(Bare Metal)*: Installs Caddy, PM2, Node.js, and Bun. 
    *   *(Docker)*: Installs Docker Compose and Traefik for dynamic routing.
*   **Database Lock-down**: Installs PostgreSQL, dynamically locks down `pg_hba.conf` so it only accepts connections from the App Node (or localhost if bare-metal), and generates automated backup scripts.
*   **Automated Maintenance**: Configures a daily `cron` job for database backups and configures `logrotate` to prevent backup logs from eating up disk space.

---

## Prerequisites

1.  **Ansible**: Install Ansible on your local machine.
    *   Arch Linux: `sudo pacman -S ansible`
    *   macOS: `brew install ansible`
    *   Ubuntu/Debian: `sudo apt install ansible`

## Setup Instructions

### Step 1: Secure SSH Access
Before Ansible can configure the server, establish secure, passwordless key-based authentication with your VPS as the `root` user.
```bash
ssh-copy-id root@<YOUR_VPS_IP>
```

### Step 2: Configure Your Variables
We provide `.example` files to prevent sensitive data from being accidentally committed to git.

1. **Inventory**: 
   Copy the inventory example and update it with your server's IP (or SSH alias):
   ```bash
   cp inventory/production.ini.example inventory/production.ini
   ```
   *(Place your App servers under `[app_nodes]` and your database servers under `[db_nodes]`. If they are the same server, place the IP in both).*

2. **Global Variables**: 
   Copy the variables example and configure your deployment mode:
   ```bash
   cp group_vars/all.yml.example group_vars/all.yml
   ```
   *Make sure to set `deployment_mode` to either `"bare_metal"` or `"docker"`.*

3. **Vault (Secrets)**:
   Create an encrypted Vault file to store your sensitive variables (like database passwords).
   ```bash
   ansible-vault create group_vars/vault.yml
   ```
   *Example contents:*
   ```yaml
   db_password: "your_super_secret_password"
   
   # If using Docker:
   ghcr_user: "your_github_username"
   ghcr_token: "your_github_personal_access_token"
   acme_email: "you@example.com"
   ```

---

## Usage & Commands

This project uses a `Makefile` to drastically simplify deployment.

### 1. Test Connection
Verify that Ansible can communicate with all the servers defined in your inventory:
```bash
make ping
```

### 2. Full Server Bootstrap (The Magic Button)
To completely secure and provision all servers from scratch (it will ask for your Ansible Vault password):
```bash
make setup-all
```

### 3. Target Specific Infrastructure
If you are only provisioning a new app server, or want to apply new Traefik/Caddy configurations:
```bash
make setup-app
```

If you are only provisioning or updating a database server:
```bash
make setup-db
```

### 4. Manage Secrets
To securely open and edit your Vault file later:
```bash
make edit-vault
```

---

## Architecture Breakdown

*   `roles/common/`: Runs on ALL servers. Hardens SSH, sets Timezone, configures UFW/fail2ban, sets up Swap memory, and enables Unattended Upgrades.
*   `roles/docker/`: (Conditional) Runs on App Nodes only if `deployment_mode == 'docker'`. Installs the Docker daemon.
*   `roles/app_node/`: Runs on App Nodes. Conditionally sets up either Traefik/Docker-Compose or Caddy/PM2/Bun based on your `deployment_mode`.
*   `roles/db_node/`: Runs on DB Nodes. Installs PostgreSQL, configures user permissions, strictly limits connections to the App Node IP (or localhost), and generates the daily backup cron job.

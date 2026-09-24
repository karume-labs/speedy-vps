# Speedy VPS Configuration

A lightning-fast, production-ready Ansible orchestration repository designed to bootstrap and secure new VPS instances (like Contabo, DigitalOcean, or Hetzner) in minutes.

This setup automatically splits your infrastructure into a **Dockerized Application Node** (with Traefik auto-routing) and a **Native Database Node** (with automated backups and strict firewall rules), perfectly mirroring a scalable web architecture.

---

## Features Included Out-of-the-Box

*   **Security First**: Disables root password SSH login, configures `ufw` firewalls, and sets up `fail2ban`.
*   **Stability**: Forces the `UTC` timezone, sets up automated `unattended-upgrades` for security patches, and automatically allocates a 2GB Swap file to prevent Out-Of-Memory crashes.
*   **Zero-Config Routing**: Installs Docker and uses Traefik as a reverse proxy, dynamically discovering containers and assigning SSL certificates via `labels`.
*   **Database Lock-down**: Installs PostgreSQL, dynamically locks down `pg_hba.conf` so it only accepts connections from the App Node, and generates automated backup scripts.
*   **Automated Maintenance**: Configures a daily `cron` job for database backups and automatically configures `logrotate` to prevent backup logs from eating up disk space.
*   **Zero-Touch Deployments**: Automatically templates your `.env` files and runs `docker compose up -d`.

---

## Prerequisites

1.  **Ansible**: Install Ansible on your local machine.
    *   Arch Linux: `sudo pacman -S ansible`
    *   macOS: `brew install ansible`
    *   Ubuntu/Debian: `sudo apt install ansible`

## Setup Instructions

### Step 1: Secure SSH Access
Before Ansible can configure the server, you must establish secure, passwordless key-based authentication with your VPS as the `root` user.

*   **Using `ssh-copy-id` (Recommended)**
    ```bash
    ssh-copy-id root@<YOUR_VPS_IP>
    ```
    *(It will prompt you for the root password once, then copy your key. Once Ansible runs, password logins will be permanently disabled.)*

### Step 2: Define your Servers
Update the IP addresses and server assignments in `inventory/production.ini`. Place your App servers under `[app_nodes]` and your database servers under `[db_nodes]`.

### Step 3: Define your Variables
1.  Open `group_vars/all.yml` and set your standard `app_name`.
2.  Create an encrypted Vault file to store your sensitive variables (like Container Registry tokens or database passwords).
    ```bash
    ansible-vault create group_vars/vault.yml
    ```
    *Inside this file, you should define your database password, e.g.:*
    ```yaml
    db_password: "your_super_secret_password"
    ```

---

## Usage & Commands

This project uses a `Makefile` to drastically simplify deployment.

### 1. Test Connection
Verify that Ansible can communicate with all the servers defined in your inventory without prompting for a password:
```bash
make ping
```

### 2. Full Server Bootstrap (The Magic Button)
To completely secure and provision all servers from scratch (it will ask for your Ansible Vault password):
```bash
make setup-all
```

### 3. Target Specific Infrastructure
If you are only provisioning a new app server, or you pushed a new Docker image and want Ansible to pull it and restart the stack:
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
*   `roles/docker/`: Runs on App Nodes. Installs the Docker daemon and Docker Compose plugin.
*   `roles/app_node/`: Runs on App Nodes. Templates out the `.env` file containing the dynamic `DATABASE_URL`, copies the Traefik `docker-compose.yml`, pulls the latest images, and launches the stack.
*   `roles/db_node/`: Runs on DB Nodes. Installs PostgreSQL, configures user permissions, strictly limits connections to the App Node IP, and generates the daily backup cron job.

# Speedy-VPS

A lightning-fast, ultra-secure, and completely **decoupled** Ansible infrastructure engine.

Speedy-VPS is a stateless library of Ansible roles and playbooks. You **do not** place your app's configurations or secrets inside this repository. Instead, you copy the `template-infra/` folder into your specific application's codebase and run the playbooks from there.

This guarantees that `speedy-vps` remains completely generic and reusable across all your projects.

---

## Architecture Modes

Two variables control how every component is deployed. They are independent of each other.

**`deployment_mode`** — controls the App layer:
- `bare_metal`: Installs Caddy, Node.js 22, Bun, and PM2 directly onto the OS.
- `docker`: Installs Docker and Traefik. Your app runs in a container pulled from a registry.

**`db_deployment_mode`** — controls the Database layer:
- `bare_metal`: Installs PostgreSQL directly onto the OS via `apt`.
- `docker`: Spins up a PostgreSQL Docker container.

See the [Topology Guide](#topology-guide) for all combinations.

---

## Prerequisites

Before starting, make sure you have the following installed on your local machine:

- **Ansible** — `pip install ansible`
- **make** — comes pre-installed on macOS/Linux
- **rsync** — comes pre-installed on macOS/Linux; `apt install rsync` on Ubuntu
- **An SSH key** with root access to your VPS already added to the server

---

## Setup Guide

Follow these steps every time you want to deploy a new application.

### Step 1: Copy the template into your app

From within your application's root directory, clone the speedy-vps template:

```bash
# From your app's root directory
git clone git@github.com:karume-labs/speedy-vps.git .speedy-vps-tmp
cp -r .speedy-vps-tmp/template-infra ./infra
rm -rf .speedy-vps-tmp
```

You will now have this structure inside your app:

```
your-app/
  infra/
    .gitignore
    .github/
      workflows/
        deploy.yml          # CI/CD pipeline (optional)
    inventory/
      production.ini        # Server IP addresses & SSH config
    group_vars/
      all.yml               # App name, domain, deployment modes
      vault.yml             # Secrets (gitignored, never committed)
    Makefile                # Runs Ansible (auto-downloads the engine)
    deploy-baremetal.sh     # Deploy script for bare metal apps
    deploy-docker.sh        # Deploy script for Docker apps
```

### Step 2: Configure the server inventory

Open `infra/inventory/production.ini`.

This file tells Ansible which servers exist and how to connect to them. The `[app_nodes]` group receives your app. The `[db_nodes]` group receives the database.

**Single server (app and DB on the same machine):**
```ini
[app_nodes]
my-app-server ansible_host=123.45.67.89 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa

[db_nodes]
my-app-server ansible_host=123.45.67.89 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
```

**Two servers (app on one, DB on another):**
```ini
[app_nodes]
my-app-server ansible_host=111.11.11.11 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa

[db_nodes]
my-db-server ansible_host=222.22.22.22 ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
```

> The alias on the left (e.g. `my-app-server`) must match the `SERVER_ALIAS` variable in your deploy script and your local `~/.ssh/config`.

### Step 3: Configure app variables

Open `infra/group_vars/all.yml` and fill in your values:

```yaml
---
# The name of your app. Used for:
#   - The deployment directory: /opt/apps/<app_name>
#   - The PostgreSQL database name and user
app_name: "my-awesome-app"

# The domain name or IP address Caddy/Traefik will serve traffic on.
# Use your IP address during initial testing, then switch to a real domain.
domain_name: "123.45.67.89"

# Deployment mode for the App layer ('bare_metal' or 'docker')
deployment_mode: "bare_metal"

# Deployment mode for the Database layer ('bare_metal' or 'docker')
db_deployment_mode: "bare_metal"
```

### Step 4: Set the database password

Create the vault file at `infra/group_vars/vault.yml`. This file is already listed in `infra/.gitignore` and will never be committed.

**Option A — Plaintext (simple local development):**

Create the file manually:
```yaml
# infra/group_vars/vault.yml
db_password: "your-super-secure-password"
```

**Option B — Ansible Vault (recommended for teams):**

```bash
# Generate a strong password
openssl rand -base64 24

# Create an encrypted vault file (you will be prompted for a vault password)
cd infra/
ansible-vault create group_vars/vault.yml
```

Inside the editor that opens, type:
```yaml
db_password: "your-super-secure-password"
```

If you use Ansible Vault, create `infra/.vault_pass` containing only your vault password (also gitignored), then add `--vault-password-file .vault_pass` to your Makefile's ansible-playbook command.

> Ansible will automatically inject this password into `.env` on the server during provisioning. Your deploy scripts never handle secrets.

### Step 5: Set up your local SSH config

So that `rsync` and `ssh` commands in your deploy script can use the alias (e.g. `my-app-server`) instead of the raw IP, add an entry to `~/.ssh/config` on your local machine:

```
Host my-app-server
  HostName 123.45.67.89
  User root
  IdentityFile ~/.ssh/id_rsa
```

Replace `my-app-server` with whatever alias you used in `production.ini`.

### Step 6: Provision the server

Navigate to your `infra/` folder and run:

```bash
cd infra/
make setup-all
```

The `Makefile` will automatically:
1. Clone the `speedy-vps` engine from GitHub into a local `.speedy-vps/` cache (or pull updates if it already exists).
2. Run the Ansible playbooks against your server.

What Ansible installs depends on your `deployment_mode` and `db_deployment_mode` settings. After provisioning, the server will have:
- A hardened firewall (UFW), fail2ban, and SSH key-only access
- Your chosen web server (Caddy or Traefik) configured and running
- PostgreSQL set up with a dedicated database and user for your app
- A `.env` file at `/opt/apps/<app_name>/.env` pre-populated with your `DATABASE_URL`

### Step 7: Configure and run your deploy script

**For bare metal apps**, copy `deploy-baremetal.sh` to your app root and edit the variables at the top:

```bash
cp infra/deploy-baremetal.sh ./deploy.sh
chmod +x deploy.sh
```

Open `deploy.sh` and set:
```bash
APP_NAME="my-awesome-app"   # Must match app_name in all.yml
SERVER_ALIAS="my-app-server" # Must match your ~/.ssh/config Host alias
```

Then update the PM2 start command to match your framework:
```bash
# For standard Next.js (SSR):
pm2 start bun --name '$APP_NAME' -- run start

# For Next.js with output: export (static):
pm2 start "npx serve@latest out -p 3000" --name '$APP_NAME'

# For a plain Node/Bun server:
pm2 start bun --name '$APP_NAME' -- run start
```

Run it:
```bash
./deploy.sh
```

**For Docker apps**, copy `deploy-docker.sh` to your app root and edit the variables:

```bash
cp infra/deploy-docker.sh ./deploy.sh
chmod +x deploy.sh
```

Open `deploy.sh` and set:
```bash
APP_NAME="my-awesome-app"
SERVER_ALIAS="my-app-server"
IMAGE_NAME="ghcr.io/your-username/my-awesome-app:latest"
```

Run it:
```bash
./deploy.sh
```

---

## Optional: Automated CI/CD with GitHub Actions

The template includes a GitHub Actions workflow at `.github/workflows/deploy.yml` that automatically runs your `deploy.sh` every time you push to `main`.

To activate it:

1. Copy the workflow file into your app's `.github/workflows/` folder:
   ```bash
   mkdir -p .github/workflows
   cp infra/.github/workflows/deploy.yml .github/workflows/deploy.yml
   ```

2. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** and add two repository secrets:
   - `SSH_PRIVATE_KEY` — the full contents of your private key file (e.g. `~/.ssh/id_rsa`)
   - `SERVER_IP` — your VPS IP address

3. Push to `main`. GitHub will handle the rest.

---

## Topology Guide

The two variables in `group_vars/all.yml` combined with the two groups in `production.ini` cover every deployment topology.

### Case 1: All Bare Metal (Single Server)

Both app and database installed directly on the OS of one machine.

```ini
# inventory/production.ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root
```
```yaml
# group_vars/all.yml
deployment_mode: "bare_metal"
db_deployment_mode: "bare_metal"
```

*Installs: Caddy, Node.js 22, Bun, PM2, and PostgreSQL (via apt) all on `serverA`.*

---

### Case 2: All Docker (Single Server)

Both app and database run in Docker containers on one machine.

```ini
# inventory/production.ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root
```
```yaml
# group_vars/all.yml
deployment_mode: "docker"
db_deployment_mode: "docker"
```

*Installs: Docker, Traefik, and a PostgreSQL container — all on `serverA`.*

---

### Case 3: Hybrid (Single Server)

App runs via Docker (good for CI/CD parity). Database installed natively for raw I/O performance.

```ini
# inventory/production.ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root
```
```yaml
# group_vars/all.yml
deployment_mode: "docker"
db_deployment_mode: "bare_metal"
```

*Installs: Docker + Traefik for the app, PostgreSQL via apt for the database — on `serverA`.*

---

### Case 4: All Docker (Two Servers)

App and database on separate machines, both running via Docker.

```ini
# inventory/production.ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverB ansible_host=222.22.22.22 ansible_user=root
```
```yaml
# group_vars/all.yml
deployment_mode: "docker"
db_deployment_mode: "docker"
```

*Server A: Docker + Traefik + app container. Server B: Docker + PostgreSQL container. The database firewall is automatically locked to only accept connections from Server A's IP.*

---

### Case 5: Hybrid (Two Servers)

App on Server A via Docker. Database on dedicated Server B installed natively for maximum I/O.

```ini
# inventory/production.ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverB ansible_host=222.22.22.22 ansible_user=root
```
```yaml
# group_vars/all.yml
deployment_mode: "docker"
db_deployment_mode: "bare_metal"
```

*Server A: Docker + Traefik + app container. Server B: Native PostgreSQL with daily cron backups. Firewall on Server B locked to Server A's IP only.*

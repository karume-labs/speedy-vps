# Speedy-VPS

A lightning-fast, ultra-secure, and completely **decoupled** Ansible infrastructure engine. 

Speedy-VPS is designed to act as a centralized library of Ansible roles and playbooks. You **do not** place your app's configurations or secrets inside this repository. Instead, you copy the `template-infra/` folder into your specific application's codebase, and run the playbooks from there.

This guarantees that `speedy-vps` remains completely generic and stateless, while your apps track their own infrastructure definitions!

---

## Architecture Modes

Speedy-VPS natively supports two deployment architectures. You select which one to use via the `deployment_mode` variable in your app's `group_vars/all.yml`.

### 1. Bare Metal (`deployment_mode: "bare_metal"`)
Perfect for Next.js, Node.js, and static sites. Installs everything directly onto the OS for maximum performance.
- **Web Server:** Caddy (Auto-configures reverse proxy & HTTPS)
- **Runtime:** Node.js 22.x & Bun
- **Process Manager:** PM2 (Configured to survive server reboots)
- **Database:** PostgreSQL (Secured, UFW restricted, daily auto-backups)
- **Security:** UFW Firewall, Unattended Upgrades, SSH Key-only access.

### 2. Docker (`deployment_mode: "docker"`)
Perfect for complex microservices or containerized apps.
- **Web Server:** Traefik (Auto-configures SSL via Let's Encrypt)
- **Runtime:** Docker & Docker Compose v2
- **Database:** PostgreSQL
- **Security:** UFW Firewall, Unattended Upgrades, SSH Key-only access.

---

## Step-by-Step Usage Guide

Follow these exact steps to provision a server for a new application.

### Step 1: Initialize your App's Infra Folder
1. Inside your application's codebase (e.g., `townlink-limited/`), create a new folder called `infra/`.
2. Copy the entire contents of `speedy-vps/template-infra/` into your new `infra/` folder.
   ```bash
   cp -r /path/to/speedy-vps/template-infra/* /path/to/your-app/infra/
   ```

### Step 2: Configure the Inventory
Open `infra/inventory/production.ini` and set your server's IP address, SSH user, and private key path.
```ini
[app_nodes]
my-app-server ansible_host=123.45.67.89 ansible_user=root ansible_ssh_private_key_file=~/.ssh/your-key
```

### Step 3: Configure Variables
Open `infra/group_vars/all.yml` and define your app.
```yaml
app_name: "my-awesome-app"
domain_name: "123.45.67.89" # Or your actual domain
deployment_mode: "bare_metal" # Or "docker"
```

### Step 4: Secure the Database Password
Create an encrypted vault for your database password (or use a plaintext file locally if you prefer, as long as it is git-ignored).
1. Generate a secure password: `openssl rand -base64 24`
2. Save it in `infra/group_vars/vault.yml`:
   ```yaml
   db_password: "YOUR_SECURE_PASSWORD"
   ```
3. **CRITICAL:** Ensure `infra/.gitignore` ignores `.vault_pass` and `group_vars/vault.yml`.

### Step 5: Provision the Server
Navigate to your app's `infra/` folder in the terminal and execute the `Makefile`:
```bash
cd /path/to/your-app/infra
make setup-all
```
*Note: Make sure the `SPEEDY_VPS_DIR` variable inside `infra/Makefile` correctly points to the relative path of the `speedy-vps` repository on your local machine.*

### Step 6: Deploy your Code!
Inside the templates, you were provided a `deploy-baremetal.sh` file. 
1. Move it to the root of your app (`mv infra/deploy-baremetal.sh ./deploy.sh`).
2. Customize the `APP_NAME` and `SERVER_ALIAS` at the top of the script.
3. Run `./deploy.sh` to Rsync your code, build it with Bun, and serve it via PM2!

---

## Speedy-VPS Topology Guide

The `speedy-vps` engine is incredibly flexible. By separating the App and the Database into distinct Ansible roles, you can orchestrate complex multi-server and hybrid deployments simply by tweaking two files in your `infra/` folder:

1. **`infra/inventory/production.ini`**: Controls *where* the apps and databases live (Same server vs Multiple servers).
2. **`infra/group_vars/all.yml`**: Controls *how* they are installed (`bare_metal` vs `docker`).

Here is exactly how to configure the engine for 5 different topology cases.

### Case 1: All Bare Metal (Single Server)
*Both the App and Database live on the same VPS, installed directly onto the OS for maximum raw performance.*

**Inventory (`production.ini`)**
```ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root
```
**Variables (`group_vars/all.yml`)**
```yaml
deployment_mode: "bare_metal"
db_deployment_mode: "bare_metal"
```
*Result:* Caddy, PM2, Bun, and PostgreSQL (via apt) are all installed on `serverA`.

---

### Case 2: All Docker (Single Server)
*Both the App and Database live on the same VPS, but both run in isolated Docker containers.*

**Inventory (`production.ini`)**
```ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root
```
**Variables (`group_vars/all.yml`)**
```yaml
deployment_mode: "docker"
db_deployment_mode: "docker"
```
*Result:* Docker is installed on `serverA`. Traefik routes traffic to your App's Docker container, and a separate PostgreSQL Docker container spins up on the same machine.

---

### Case 3: Hybrid (Single Server)
*The App runs via Docker (for easy CI/CD parity), but the Database is installed via Bare Metal (for native disk I/O performance).*

**Inventory (`production.ini`)**
```ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root
```
**Variables (`group_vars/all.yml`)**
```yaml
deployment_mode: "docker"
db_deployment_mode: "bare_metal"
```
*Result:* Docker and Traefik are installed on `serverA` for your App. PostgreSQL is installed directly onto Ubuntu via `apt` on the same machine.

---

### Case 4: All Docker (Multi-Server)
*You scale out to two different servers. The App runs via Docker on Server A, and the Database runs via Docker on Server B.*

**Inventory (`production.ini`)**
```ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverB ansible_host=222.22.22.22 ansible_user=root
```
**Variables (`group_vars/all.yml`)**
```yaml
deployment_mode: "docker"
db_deployment_mode: "docker"
```
*Result:* Docker is installed on both machines. Server A only gets the App container and Traefik. Server B only gets the PostgreSQL container. Speedy-VPS automatically configures the database firewall to only accept connections from Server A's IP address.

---

### Case 5: Hybrid (Multi-Server)
*The most powerful setup: The App scales via Docker on Server A, but the Database runs natively on Bare Metal on a dedicated Server B for maximum I/O.*

**Inventory (`production.ini`)**
```ini
[app_nodes]
serverA ansible_host=111.11.11.11 ansible_user=root

[db_nodes]
serverB ansible_host=222.22.22.22 ansible_user=root
```
**Variables (`group_vars/all.yml`)**
```yaml
deployment_mode: "docker"
db_deployment_mode: "bare_metal"
```
*Result:* Server A gets Docker, Traefik, and your App container. Server B gets a purely native PostgreSQL `apt` installation with automatic daily cron backups. The firewall on Server B is automatically locked down to only accept port 5432 traffic from Server A.

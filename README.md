# Speedy-VPS 🚀

A lightning-fast, ultra-secure, and completely **decoupled** Ansible infrastructure engine. 

Speedy-VPS is designed to act as a centralized library of Ansible roles and playbooks. You **do not** place your app's configurations or secrets inside this repository. Instead, you copy the `template-infra/` folder into your specific application's codebase, and run the playbooks from there.

This guarantees that `speedy-vps` remains completely generic and stateless, while your apps track their own infrastructure definitions!

---

## 🏗️ Architecture Modes

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

## 📖 Step-by-Step Usage Guide

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

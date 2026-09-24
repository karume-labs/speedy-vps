# Speedy VPS Configuration

A fast, reusable Ansible setup to bootstrap and secure new VPS instances in minutes. 

## Prerequisites

1.  **Ansible**: Install Ansible on your local machine.
    *   Arch Linux: `sudo pacman -S ansible`
    *   macOS: `brew install ansible`
    *   Ubuntu/Debian: `sudo apt install ansible`
2.  **SSH Access**: Ensure your local machine's SSH key is added to the `~/.ssh/authorized_keys` file of the target VPS as the `root` user.

    If you haven't set up key-based authentication yet, you can easily copy your public key to the server:
    
    *   **Option 1: Using `ssh-copy-id` (Recommended)**
        ```bash
        ssh-copy-id root@<YOUR_VPS_IP>
        ```
        *It will prompt you for the root password once, then copy your key automatically.*

    *   **Option 2: Manual copy (if `ssh-copy-id` isn't available)**
        ```bash
        cat ~/.ssh/id_rsa.pub | ssh root@<YOUR_VPS_IP> "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat >> ~/.ssh/authorized_keys"
        ```

## Setup

1.  Update the IP addresses and server assignments in `inventory/production.ini`.
2.  Create a `group_vars/vault.yml` file to store any sensitive variables (like Container Registry tokens or database passwords). Encrypt it using Ansible Vault:
    ```bash
    ansible-vault create group_vars/vault.yml
    ```

## Usage

We use a `Makefile` to simplify running the Ansible playbooks.

### 1. Test Connection
Verify that Ansible can communicate with the newly provisioned servers:
```bash
make ping
```

### 2. Full Server Bootstrap
To fully secure and provision all servers from scratch (it will prompt for your Ansible Vault password):
```bash
make setup-all
```

### 3. Target Specific Infrastructure
If you are only provisioning or updating an app server (Docker host):
```bash
make setup-app
```

If you are only provisioning or updating a database server:
```bash
make setup-db
```

### 4. Edit Secrets
To securely open and edit your Vault file:
```bash
make edit-vault
```

.PHONY: ping setup-all edit-vault

INVENTORY ?= inventory/production.ini
SPEEDY_VPS_REPO ?= git@github.com:karume-labs/speedy-vps.git
SPEEDY_VPS_DIR ?= .speedy-vps

init:
	@if [ ! -d "$(SPEEDY_VPS_DIR)" ]; then \
		echo "Downloading speedy-vps engine..."; \
		git clone $(SPEEDY_VPS_REPO) $(SPEEDY_VPS_DIR); \
	else \
		cd $(SPEEDY_VPS_DIR) && git pull origin main; \
	fi

ping: init
	ansible all -i $(INVENTORY) -m ping

setup-all: init
	ansible-playbook -i $(INVENTORY) $(SPEEDY_VPS_DIR)/playbooks/site.yml

edit-vault:
	ansible-vault edit group_vars/vault.yml

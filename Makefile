.PHONY: ping setup-all setup-app setup-db setup-base edit-vault

INVENTORY ?= inventory/production.ini

ping:
	ansible all -i $(INVENTORY) -m ping

setup-all:
	ansible-playbook -i $(INVENTORY) playbooks/site.yml --ask-vault-pass

setup-base:
	ansible-playbook -i $(INVENTORY) playbooks/setup_base.yml --ask-vault-pass

setup-app:
	ansible-playbook -i $(INVENTORY) playbooks/setup_app.yml --ask-vault-pass

setup-db:
	ansible-playbook -i $(INVENTORY) playbooks/setup_db.yml --ask-vault-pass

edit-vault:
	ansible-vault edit group_vars/vault.yml

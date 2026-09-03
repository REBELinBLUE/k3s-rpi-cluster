INVENTORY = inventory.yaml
ANSIBLE_DIR = ./ansible

flash:
	./scripts/flash.sh

secrets:
	./scripts/update-sealed-secrets.sh

# Initial setup
master:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) master.yaml

workers:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) workers.yaml

# K3S setup and teardown
cluster:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) install.yaml

reset:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) uninstall.yaml

# Helpers
reboot:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) reboot.yaml

update:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) update.yaml

shutdown:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) shutdown.yaml

lint:
	cd $(ANSIBLE_DIR) && ansible-galaxy collection install -r requirements.yml && ansible-lint

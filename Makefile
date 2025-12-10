INVENTORY = inventory.yaml
ANSIBLE_DIR = ./ansible

flash:
	./scripts/flash.sh

bootstrap:
	./scripts/setup.sh

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
config:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) get-config.yaml

reboot:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) reboot.yaml

shutdown:
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(INVENTORY) shutdown.yaml

lint:
	cd $(ANSIBLE_DIR) && ansible-lint

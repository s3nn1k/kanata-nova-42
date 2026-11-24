.PHONY: lint check-config

lint:
	bash -n apply.sh
	bash -n scripts/xremap-apply.sh

check-config:
	kanata --cfg configs/cfqv8.kbd --check

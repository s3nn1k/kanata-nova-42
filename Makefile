.PHONY: lint install check-config

lint:
	bash -n scripts/install.sh
	bash -n scripts/xremap-apply.sh
	shellcheck scripts/install.sh
	shellcheck scripts/xremap-apply.sh

install:
	./scripts/install.sh

check-config:
	kanata --cfg configs/cfqv8.kbd --check

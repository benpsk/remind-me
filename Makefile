PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
SYSTEMD_USER_DIR ?= $(HOME)/.config/systemd/user
SYSTEMD_UNIT_NAME ?= remindme.service
SYSTEMD_UNIT_SRC ?= systemd/$(SYSTEMD_UNIT_NAME)
REPO_DIR ?= $(abspath $(CURDIR))
INSTALL_BIN ?= $(BINDIR)/remindme

.PHONY: install uninstall systemd-install systemd-uninstall systemd-enable systemd-disable

install:
	mkdir -p "$(BINDIR)"
	install -m 0755 remindme "$(INSTALL_BIN)"
	@echo "Installed to $(INSTALL_BIN)"
	$(MAKE) systemd-install
	$(MAKE) systemd-enable
	@echo "Install complete: CLI + systemd user unit enabled"

uninstall:
	$(MAKE) systemd-uninstall
	rm -f "$(INSTALL_BIN)"
	@echo "Removed $(INSTALL_BIN)"
	@echo "Uninstall complete: CLI + systemd user unit removed"

systemd-install:
	mkdir -p "$(SYSTEMD_USER_DIR)"
	sed \
		-e "s|@REPO_DIR@|$(REPO_DIR)|g" \
		-e "s|@INSTALL_BIN@|$(INSTALL_BIN)|g" \
		"$(SYSTEMD_UNIT_SRC)" > "$(SYSTEMD_USER_DIR)/$(SYSTEMD_UNIT_NAME)"
	@echo "Generated unit at $(SYSTEMD_USER_DIR)/$(SYSTEMD_UNIT_NAME)"
	@echo "ExecStart uses INSTALL_BIN=$(INSTALL_BIN)"
	@echo "Optional env file: ~/.config/remindme.env (loaded automatically if present)"
	systemctl --user daemon-reload

systemd-uninstall:
	systemctl --user disable --now "$(SYSTEMD_UNIT_NAME)" || true
	rm -f "$(SYSTEMD_USER_DIR)/$(SYSTEMD_UNIT_NAME)"
	systemctl --user daemon-reload
	@echo "Removed $(SYSTEMD_USER_DIR)/$(SYSTEMD_UNIT_NAME)"

systemd-enable:
	systemctl --user daemon-reload
	systemctl --user enable --now "$(SYSTEMD_UNIT_NAME)"

systemd-disable:
	systemctl --user disable --now "$(SYSTEMD_UNIT_NAME)"

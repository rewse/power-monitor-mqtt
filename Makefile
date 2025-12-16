# Power Monitor MQTT Publisher Makefile

SCRIPT_NAME = power-monitor-mqtt.sh
CONFIG_DIR = $(HOME)/.config/power-monitor-mqtt
CONFIG_FILE = $(CONFIG_DIR)/config
INSTALL_DIR = $(HOME)/.local/bin

.PHONY: help install uninstall setup-config test clean deps

help:
	@echo "Power Monitor MQTT Publisher"
	@echo ""
	@echo "Available targets:"
	@echo "  deps         Install dependencies via Homebrew"
	@echo "  setup-config Create configuration directory and example config"
	@echo "  install      Install script to ~/.local/bin"
	@echo "  uninstall    Remove installed script"
	@echo "  test         Run test mode"
	@echo "  clean        Remove configuration and logs"
	@echo "  help         Show this help message"

deps:
	@echo "Installing dependencies..."
	brew install mosquitto jq

setup-config:
	@echo "Setting up configuration..."
	mkdir -p $(CONFIG_DIR)
	@if [ ! -f $(CONFIG_FILE) ]; then \
		cp config.example $(CONFIG_FILE); \
		echo "Configuration file created at $(CONFIG_FILE)"; \
		echo "Please edit the configuration file before running the script."; \
	else \
		echo "Configuration file already exists at $(CONFIG_FILE)"; \
	fi

install: setup-config
	@echo "Installing script..."
	mkdir -p $(INSTALL_DIR)
	cp $(SCRIPT_NAME) $(INSTALL_DIR)/
	chmod +x $(INSTALL_DIR)/$(SCRIPT_NAME)
	@echo "Script installed to $(INSTALL_DIR)/$(SCRIPT_NAME)"
	@echo ""
	@echo "You can now run:"
	@echo "  $(INSTALL_DIR)/$(SCRIPT_NAME) --help"

uninstall:
	@echo "Uninstalling script..."
	rm -f $(INSTALL_DIR)/$(SCRIPT_NAME)
	@echo "Script removed from $(INSTALL_DIR)/$(SCRIPT_NAME)"

test:
	@echo "Running test mode..."
	./$(SCRIPT_NAME) --test

clean:
	@echo "Cleaning up..."
	rm -rf $(CONFIG_DIR)
	@echo "Configuration directory removed"



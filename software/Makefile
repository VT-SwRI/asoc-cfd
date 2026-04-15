VENV_DIR := $(HOME)/venv
PYTHON   := $(VENV_DIR)/bin/python
PIP      := $(VENV_DIR)/bin/pip

.PHONY: all gui clean

all:
	@echo "make:                                      "
	@echo "    	gui: Build GUI and install dependencies"
	@echo "    	clean: Remove virtual environment      "


$(VENV_DIR):
	python3 -m venv $(VENV_DIR)

gui: $(VENV_DIR)
	@echo "Installing requirements into $(VENV_DIR)..."
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	@echo "Done! Run with: $(PYTHON) main.py"

clean:
	rm -rf $(VENV_DIR)
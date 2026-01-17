VENV ?= .venv
PYTEST = $(VENV)/bin/pytest

.PHONY: venv test

venv:
	python3 -m venv $(VENV)
	$(VENV)/bin/pip install --upgrade pip
	$(VENV)/bin/pip install -r requirements.txt

test: venv
	$(PYTEST) -q

.PHONY: dev install-pre-commit coverage

dev: venv
	$(VENV)/bin/pip install -r requirements-dev.txt

install-pre-commit: dev
	$(VENV)/bin/pre-commit install

coverage: dev
	$(VENV)/bin/pytest --cov=src --cov-report=term-missing -q

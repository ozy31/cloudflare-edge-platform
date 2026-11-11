SHELL := /bin/bash
include versions.env
export

TF_DIR := terraform

.PHONY: fmt validate lint test check e2e e2e-down analytics

fmt: ## Format all Terraform code
	terraform fmt -recursive $(TF_DIR)

validate: ## terraform init (no backend) + validate
	terraform -chdir=$(TF_DIR) init -backend=false -input=false >/dev/null
	terraform -chdir=$(TF_DIR) validate

lint: ## tflint across root and modules
	tflint --chdir=$(TF_DIR) --init >/dev/null
	tflint --chdir=$(TF_DIR) --recursive

MODULE_TESTS := dns tunnel waf rate-limits

test: ## terraform test (mocked provider) for the root stack and modules
	terraform -chdir=$(TF_DIR) test
	@for m in $(MODULE_TESTS); do \
	  echo "== module $$m"; \
	  terraform -chdir=$(TF_DIR)/modules/$$m init -backend=false -input=false >/dev/null && \
	  terraform -chdir=$(TF_DIR)/modules/$$m test || exit 1; \
	done

check: ## Everything CI runs that needs no Cloudflare account
	terraform fmt -check -recursive $(TF_DIR)
	$(MAKE) validate lint test

e2e: ## kind e2e: Pod Security admission, no exposed services, NetworkPolicy isolation
	tests/e2e/run.sh

e2e-down: ## Delete the e2e kind cluster
	kind delete cluster --name edge-e2e

analytics: ## Generate synthetic Logpush data and test the DuckDB queries
	python3 -m venv .venv && .venv/bin/pip install -q -r analytics/requirements.txt
	.venv/bin/python -m pytest -q analytics/tests

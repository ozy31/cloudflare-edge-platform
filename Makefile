SHELL := /bin/bash
include versions.env
export

TF_DIR := terraform

.PHONY: fmt validate lint check

fmt: ## Format all Terraform code
	terraform fmt -recursive $(TF_DIR)

validate: ## terraform init (no backend) + validate
	terraform -chdir=$(TF_DIR) init -backend=false -input=false >/dev/null
	terraform -chdir=$(TF_DIR) validate

lint: ## tflint across root and modules
	tflint --chdir=$(TF_DIR) --init >/dev/null
	tflint --chdir=$(TF_DIR) --recursive

check: ## Everything CI runs that needs no Cloudflare account
	terraform fmt -check -recursive $(TF_DIR)
	$(MAKE) validate lint

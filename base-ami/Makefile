SHELL  := /bin/bash
.DEFAULT_GOAL := usage
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
NC     := \033[0m # No Color

BUILD_TYPE   ?= local
GIT_REVISION ?= local
GIT_BRANCH   ?= local
GIT_REPO     ?= local
VERSION      ?= local
PACKER_BUILDER ?= docker

export AWS_DEFAULT_REGION  := ap-southeast-2
export AMI_NAME := app_name-base
export SOURCE_AMI_NAME := amzn2-ami-hvm-2.0.20190115-x86_64-gp2

usage:
	@printf "\n################ ${RED} USAGE ${NC} #####################\n\n"
	@printf "${YELLOW}make build ${GREEN}# Build ami in a given env.${NC}\n"
	@printf "\n"
	@exit 1

get-sysdig-key:
	aws ssm get-parameter --name /app_name/sysdig/access-key --with-decryption --query 'Parameter.Value' --output text|awk '{print "ACCESS_KEY="$$1}' > packer/files/sysdig
	@awk '{print substr($$0,0,15)}' packer/files/sysdig

#684800139755

build: get-sysdig-key
	packer build \
	-var ami_name=init-${AMI_NAME} \
	-var ami_users=1234,4566,34343 \
	-var billing_tag_value=$(BILLING_TAG_VALUE) \
	-var cloudconformity_exception=$(CLOUDCONFORMITY_TAG_VALUE) \
	-var costcentre_tag_value=$(COSTCENTRE_TAG_VALUE) \
	-var entrypoint=bootstrap.sh \
	-var git_revision=$(GIT_REVISION) \
	-var source_ami_name=${SOURCE_AMI_NAME} \
	-var source_ami_owner=amazon \
	-var security_group_name=gaming-$(ENV)-gocd-agent-packer-infra \
	-var subnet_name=$(SUBNET_NAME) \
	-var version=$(VERSION) \
	-var-file=packer/vars.json \
	packer/$(PACKER_BUILDER).json

inspec: get-sysdig-key
	packer build \
	-var ami_name=inspec-${AMI_NAME} \
	-var billing_tag_value=$(BILLING_TAG_VALUE) \
	-var cloudconformity_exception=$(CLOUDCONFORMITY_TAG_VALUE) \
	-var costcentre_tag_value=$(COSTCENTRE_TAG_VALUE) \
	-var entrypoint=inspec.sh \
	-var git_revision=$(GIT_REVISION) \
	-var source_ami_name=init-${AMI_NAME}-${GO_PIPELINE_LABEL} \
	-var source_ami_owner=1212121 \
	-var security_group_name=gaming-$(ENV)-gocd-agent-packer-infra \
	-var subnet_name=$(SUBNET_NAME) \
	-var version=$(VERSION) \
	-var-file=packer/vars.json \
	packer/$(PACKER_BUILDER).json

encrypt: get-sysdig-key
	packer build \
	-var-file=packer/vars.json \
	-var ami_name=${AMI_NAME} \
	-var ami_users="" \
	-var billing_tag_value=$(BILLING_TAG_VALUE) \
	-var cloudconformity_exception=$(CLOUDCONFORMITY_TAG_VALUE) \
	-var costcentre_tag_value=$(COSTCENTRE_TAG_VALUE) \
	-var encrypt_boot=true \
	-var entrypoint=release.sh \
	-var security_group_name=gaming-$(ENV)-gocd-agent-packer-infra \
	-var subnet_name=$(SUBNET_NAME) \
	-var git_revision=$(GIT_REVISION) \
	-var source_ami_name=init-${AMI_NAME}-${GO_PIPELINE_LABEL} \
	-var source_ami_owner=1212121 \
	-var version=$(VERSION) \
	-var ci_cleanup=disabled \
	packer/$(PACKER_BUILDER).json

# do not clean up the init images as dependent pipelines will need them
cleanup:
	packer/scripts/cleanup.sh inspec

tag:
	packer/scripts/tag.sh

release: encrypt

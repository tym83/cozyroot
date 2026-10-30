export NAME=blockstor
export NAMESPACE=cozy-$(NAME)

include ../../../hack/common-envs.mk
include ../../../hack/package.mk

test:
	helm unittest .

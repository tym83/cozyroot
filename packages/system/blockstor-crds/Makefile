export NAME=blockstor-crds
export NAMESPACE=cozy-blockstor

include ../../../hack/package.mk

test:
	helm unittest .

# Pinned ref of github.com/cozystack/blockstor to vendor CRDs from.
BLOCKSTOR_REF ?= v0.1.17

# Vendored verbatim from the upstream controller-gen output, each stamped with
# helm.sh/resource-policy: keep so a chart uninstall never garbage-collects the
# CRDs and, with them, every Resource/ResourceDefinition in the cluster -- which
# is the record of what is on the disks. The stamp is anchored on a line
# upstream controls, so count the result: one annotation per CRD, or the update
# fails. templates/ is replaced only after every CRD has been counted, so a
# failure leaves the vendored files as they were.
CRDS = controllerconfigs nodes physicaldevices resourcedefinitions resourcegroups resources snapshots storagepools
update:
	@set -e; tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
	for c in $(CRDS); do \
	  curl -fsSL "https://raw.githubusercontent.com/cozystack/blockstor/$(BLOCKSTOR_REF)/config/crd/bases/blockstor.cozystack.io_$$c.yaml" -o "$$tmp/$$c.src"; \
	  awk '/^    controller-gen.kubebuilder.io\/version:/{print; print "    helm.sh/resource-policy: keep"; next} {print}' "$$tmp/$$c.src" > "$$tmp/$$c.yaml"; \
	  n=$$(grep -c '^    helm.sh/resource-policy: keep$$' "$$tmp/$$c.yaml" || true); \
	  [ "$$n" -eq 1 ] || { echo "$$c: stamped $$n keep annotations, expected 1" >&2; exit 1; }; \
	done; \
	rm -rf templates; mkdir templates; \
	for c in $(CRDS); do mv "$$tmp/$$c.yaml" templates/$$c.yaml; done

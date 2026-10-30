bundle: {
	apiVersion: "v1alpha1"
	name:       "flux-aio"
	instances: {
		"flux": {
			module: {
				url:     "oci://ghcr.io/stefanprodan/modules/flux-aio"
				version: "latest"
			}
			namespace: "cozy-fluxcd"
			values: {
				securityProfile: "privileged"
				// source-watcher builds one ExternalArtifact per PackageSource
				// component; on the management cluster that is ~100 concurrent
				// builds during install. Give it CPU headroom so it is not
				// starved by its sibling controllers in the all-in-one pod.
				// The module has no per-controller args override for the
				// watcher, so its --concurrent bump is applied as a post-render
				// patch in the Makefile.
				controllers: watcher: resources: {
					requests: {
						cpu:    "500m"
						memory: "64Mi"
					}
					limits: memory: "1Gi"
				}
				tolerations: [{
					operator: "Exists"
					key:      "node.kubernetes.io/not-ready"
				}, {
					// Bounded on purpose. An unbounded toleration is never
					// evicted, so the pod stays bound to a node nobody can
					// reach and the Deployment, seeing its last reported
					// status, makes no replacement: with one replica Flux
					// would never come back from a lost node. The sibling
					// not-ready toleration stays unbounded — a node without a
					// network plugin is NotReady, and Flux is what installs
					// the plugin.
					operator: "Exists"
					key:      "node.kubernetes.io/unreachable"
					// NoExecute is not a narrowing: tolerationSeconds is only
					// meaningful against the taint that evicts, and the API
					// refuses the pair without it. The node controller applies
					// this taint with both effects; tolerating only NoExecute
					// also keeps the pod from being placed on a node nobody
					// can reach, which is what we want anyway.
					effect:            "NoExecute"
					tolerationSeconds: 60
				}, {
					operator:          "Exists"
					key:               "node.cilium.io/agent-not-ready"
				}, {
					operator: "Exists"
					key:      "node.cloudprovider.kubernetes.io/uninitialized"
				}]
			}
		}
	}
}

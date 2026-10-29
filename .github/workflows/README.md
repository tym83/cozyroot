# Runners

Every job that needs more than a GitHub-hosted machine takes its label from a
repository variable and falls back to a hosted runner when the variable is
unset:

| Variable         | Falls back to      | Used by                                   |
|------------------|--------------------|-------------------------------------------|
| `RUNNER_SMALL`   | `ubuntu-latest`    | package builds, unit and controller tests |
| `RUNNER_LARGE`   | `ubuntu-latest`    | release and main-branch image builds      |
| `RUNNER_XLARGE`  | `ubuntu-latest`    | end-to-end suites                         |
| `RUNNER_ARM64`   | `ubuntu-24.04-arm` | arm64 builds                              |
| `RUNNER_PROXMOX` | `ubuntu-latest`    | the Proxmox end-to-end suite              |

Upstream Cozystack names its own fleet in these labels. A fork has no access to
that fleet, so a job pinned to it waits for a runner that will never arrive:
the check neither passes nor fails, and the pull request stays unmergeable with
no failure to read. The fallbacks mean a fresh clone has working CI on the
first push.

Only the first two fall back to a hosted runner. The end-to-end suites boot
QEMU guests that ask for more vCPU and memory than a hosted machine has, and
`hack/sandbox-runner-headroom.bats` sizes each sandbox job from the class its
`runs-on` names, so `RUNNER_XLARGE`, `RUNNER_LARGE` and `RUNNER_PROXMOX` keep
the upstream class as their fallback rather than pretending a hosted runner
would do. Where no such runner exists the pull-request e2e job is skipped
instead of queueing for one that will never arrive; set `RUNNER_XLARGE` to a
real label to turn it back on.

Set a variable with:

```
gh variable set RUNNER_XLARGE --body '<label>'
```

# Image registry

The pull-request workflow pushes the images it builds. Two more variables say
where, and both are unset in a fresh clone:

| Variable        | Falls back to                 | Meaning                       |
|-----------------|-------------------------------|-------------------------------|
| `REGISTRY`      | `ghcr.io/<owner>/<repo>`      | the repository images go to   |
| `REGISTRY_HOST` | `ghcr.io`                     | the host that is logged in to |

With neither set, the jobs authenticate as the workflow's own `GITHUB_TOKEN`
and push to this repository's namespace on the GitHub registry, so a fork
builds images without being handed any credentials. Setting `REGISTRY_HOST`
switches the login to the `OCIR_USER` and `OCIR_TOKEN` secrets, which is how
upstream reaches its own registry.

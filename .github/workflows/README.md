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

The fallbacks are not equivalent machines. A hosted runner has four cores, so
the end-to-end suites are far slower there and may exhaust the disk; point
`RUNNER_XLARGE` and `RUNNER_PROXMOX` at real hardware before relying on them.
Builds and tests are fine as they are.

Set a variable with:

```
gh variable set RUNNER_XLARGE --body '<label>'
```

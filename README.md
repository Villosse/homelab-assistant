# Homelab Assistant

Homelab infrastructure configuration and deployment helper.

## Deployment Script (`deploy.sh`)

The workspace includes an enhanced deployment script, `deploy.sh`, designed to simplify and optimize NixOS deployments across your homelab nodes.

### Features

- **Dry Run Support**: Test your configurations safely using `dry-activate`.
- **Change Detection (`--only-changes`)**: Evaluates local configurations and compares them with active systems on target hosts. Skips deployment if they are identical, saving time and builder resources.
- **Dynamic Host Validation**: Automatically detects available configurations in `flake.nix`.
- **Custom IP & SSH Overrides**: Resolves host IPs automatically, allows target user overrides, and supports environment-based overrides for hosts.
- **Direct Rebuild Args Pass-Through**: Pass extra arguments directly to `nixos-rebuild` using `--`.
- **Colorized Output & Summary**: Clear status logs and a deployment status summary table.

### Usage

```bash
./deploy.sh [options] [hosts...]
```

#### Options

| Flag | Option | Description |
|------|--------|-------------|
| `-d` | `--dry-run` | Perform a dry run (uses `dry-activate` action). |
| `-c` | `--only-changes` | Only deploy if local configuration differs from remote active system. |
| `-a` | `--action ACTION` | Rebuild action (default: `switch`). Supported: `switch`, `boot`, `test`, `build`, `dry-activate`, `dry-build`. |
| `-b` | `--build-host HOST` | Specify the Nix builder IP (default: `10.201.3.146`). |
| `-l` | `--local` | Build locally instead of using a remote build host. |
| `-u` | `--user USER` | SSH user for target hosts (default: `root`). |
| `-h` | `--help` | Show usage options. |

#### Special Host Targets

- `all`: Targets all configurations defined in `flake.nix` (`dashboard`, `k3s-master`, `k3s-worker-1`, `nix-builder`).
- *Empty/Default*: If no hosts are specified, the script deploys to default hosts: `nix-builder`, `k3s-master`, and `dashboard`.

---

### Examples

#### 1. Standard Deployment
Deploy default hosts using the remote build host:
```bash
./deploy.sh
```

#### 2. Deploy Only Changes (Optimized)
Only deploy nodes whose configurations have actual changes:
```bash
./deploy.sh --only-changes
```

#### 3. Perform a Dry Run on a Specific Host
Test changes on `dashboard` without applying them:
```bash
./deploy.sh --dry-run dashboard
```

#### 4. Deploy All Hosts, Building Locally
Build all hosts locally and skip those without changes:
```bash
./deploy.sh all --local --only-changes
```

#### 5. Debug with NixOS Rebuild Trace
Pass debug flags through to `nixos-rebuild`:
```bash
./deploy.sh dashboard -- --show-trace --verbose
```

#### 6. Temporary Host IP Override
Override a host's IP via environment variable (e.g. for `k3s-worker-1`):
```bash
IP_K3S_WORKER_1="10.201.3.151" ./deploy.sh k3s-worker-1
```

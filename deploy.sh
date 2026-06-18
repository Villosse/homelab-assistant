#!/usr/bin/env bash
#
# Homelab NixOS deployment script.
#
set -euo pipefail

# Default IP mapping for configurations
declare -A HOST_IPS=(
  [nix-builder]="10.201.3.146"
  [k3s-master]="10.201.3.138"
  [nix-cache]="10.201.3.150"
  [dashboard]="10.201.3.147"
)

# Defaults
DEFAULT_BUILD_HOST="10.201.3.146"
BUILD_HOST="${DEFAULT_BUILD_HOST}"
ACTION="switch"
DRY_RUN=false
ONLY_CHANGES=false
TARGET_HOSTS=()
SSH_USER="root"
EXTRA_ARGS=()

# Colors if output is a TTY
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m' # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  BOLD=''
  NC=''
fi

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Helper to get available hosts from flake.nix
get_available_hosts() {
  nix eval .#nixosConfigurations --apply "builtins.attrNames" 2>/dev/null | tr -d '[]"'
}

# Helper to print usage/help
show_help() {
  cat <<EOF
Usage: $(basename "$0") [options] [hosts...]

Deploy NixOS configurations to homelab hosts.

Options:
  -d, --dry-run             Perform a dry run (uses 'dry-activate' action).
  -c, --only-changes        Only deploy to hosts where local configuration differs from remote system.
  -a, --action ACTION       NixOS rebuild action to perform (default: $ACTION).
                            Supported: switch, boot, test, build, dry-activate, dry-build.
  -b, --build-host HOST     Specify builder host IP or address (default: $DEFAULT_BUILD_HOST).
  -l, --local               Build locally (runs nixos-rebuild without --build-host).
  -u, --user USER           SSH user for target hosts (default: $SSH_USER).
  -h, --help                Show this help message.
  -- [args...]              Pass any remaining arguments directly to nixos-rebuild.

Available hosts (detected from flake.nix):
  $(get_available_hosts)

Special hosts:
  all                       Deploys to all hosts defined in flake.nix.

Examples:
  # Deploy to default hosts (nix-builder, k3s-master, dashboard)
  ./$(basename "$0")

  # Deploy to dashboard only
  ./$(basename "$0") dashboard

  # Dry run deployment to k3s-master
  ./$(basename "$0") --dry-run k3s-master

  # Deploy only if changes exist, building locally
  ./$(basename "$0") --only-changes --local

  # Deploy to all hosts, passing verbosity options to nixos-rebuild
  ./$(basename "$0") all -- --verbose --show-trace
EOF
}

# Normalize host name for environment variable lookup
get_host_ip() {
  local host=$1
  local env_var_name="IP_${host//-/_}"
  env_var_name="${env_var_name//./_}"
  env_var_name="${env_var_name^^}"

  if [[ -n "${!env_var_name:-}" ]]; then
    echo "${!env_var_name}"
  elif [[ -n "${HOST_IPS[$host]:-}" ]]; then
    echo "${HOST_IPS[$host]}"
  else
    echo "$host"
  fi
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
      shift
      EXTRA_ARGS+=("$@")
      break
      ;;
    -d|--dry-run)
      DRY_RUN=true
      ACTION="dry-activate"
      shift
      ;;
    -c|--only-changes)
      ONLY_CHANGES=true
      shift
      ;;
    -a|--action)
      if [[ -z "${2:-}" || "$2" =~ ^- ]]; then
        log_error "Option --action requires an argument"
        exit 1
      fi
      ACTION="$2"
      shift 2
      ;;
    -b|--build-host)
      if [[ -z "${2:-}" || "$2" =~ ^- ]]; then
        log_error "Option --build-host requires an argument"
        exit 1
      fi
      BUILD_HOST="$2"
      shift 2
      ;;
    -l|--local)
      BUILD_HOST=""
      shift
      ;;
    -u|--user)
      if [[ -z "${2:-}" || "$2" =~ ^- ]]; then
        log_error "Option --user requires an argument"
        exit 1
      fi
      SSH_USER="$2"
      shift 2
      ;;
    -h|--help|-\?)
      show_help
      exit 0
      ;;
    -*)
      log_error "Unknown option $1"
      show_help >&2
      exit 1
      ;;
    *)
      TARGET_HOSTS+=("$1")
      shift
      ;;
  esac
done

# Get available hosts from flake
ALL_HOSTS=($(get_available_hosts))

# Default hosts (matching original script behavior)
DEFAULT_HOSTS=("nix-builder" "k3s-master" "dashboard")

# If no hosts specified, use DEFAULT_HOSTS
if [[ ${#TARGET_HOSTS[@]} -eq 0 ]]; then
  TARGET_HOSTS=("${DEFAULT_HOSTS[@]}")
fi

# Expand 'all' keyword
expanded_hosts=()
for host in "${TARGET_HOSTS[@]}"; do
  if [[ "$host" == "all" ]]; then
    expanded_hosts+=("${ALL_HOSTS[@]}")
  else
    expanded_hosts+=("$host")
  fi
done
TARGET_HOSTS=("${expanded_hosts[@]}")

# Verify specified hosts exist in flake
for host in "${TARGET_HOSTS[@]}"; do
  found=false
  for avail in "${ALL_HOSTS[@]}"; do
    if [[ "$host" == "$avail" ]]; then
      found=true
      break
    fi
  done
  if [[ "$found" == "false" ]]; then
    log_warn "Host '${host}' is not defined in flake.nix configurations."
    log_info "Available hosts in flake.nix: ${ALL_HOSTS[*]}"
    
    if [[ ! -t 0 ]]; then
      log_error "Stdin is not a TTY. Cannot prompt for confirmation. Aborting."
      exit 1
    fi
    
    read -p "Do you want to deploy to '${host}' anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
done

# Track deployment summary info
DEPLOY_HOSTS=()
DEPLOY_STATUSES=()

# Deployment function
deploy_host() {
  local host=$1
  local ip
  ip=$(get_host_ip "$host")

  DEPLOY_HOSTS+=("$host")

  echo -e "\n${BOLD}${CYAN}>>> Deploying ${host} (${ip})${NC}"
  log_info "Action: ${ACTION}"
  log_info "Builder: ${BUILD_HOST:-local}"
  if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    log_info "Extra rebuild args: ${EXTRA_ARGS[*]}"
  fi

  if [[ "$ONLY_CHANGES" == "true" ]]; then
    log_info "Checking if configuration changed..."
    
    # 1. Get local out path
    local local_path
    local_path=$(nix eval --raw ".#nixosConfigurations.${host}.config.system.build.toplevel" 2>/dev/null || true)
    
    if [[ -z "$local_path" ]]; then
      log_warn "Could not evaluate local configuration path. Proceeding with deployment."
    else
      # 2. Get target remote active path
      local remote_path
      remote_path=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "${SSH_USER}@${ip}" readlink -f /run/current-system 2>/dev/null || true)
      
      if [[ -z "$remote_path" ]]; then
        log_info "Target host is unreachable or not yet running NixOS. Proceeding with deployment."
      elif [[ "$local_path" == "$remote_path" ]]; then
        log_success "Configuration is already up-to-date ($local_path). Skipping."
        DEPLOY_STATUSES+=("SKIPPED (Up-to-date)")
        return 0
      else
        log_info "Changes detected:"
        echo "  Local:  $local_path"
        echo "  Remote: $remote_path"
      fi
    fi
  fi

  # Build rebuild command
  local cmd=("nixos-rebuild" "$ACTION" "--flake" ".#${host}")
  
  # Format target host argument
  local target_dest="${ip}"
  if [[ "$target_dest" != *@* ]]; then
    target_dest="${SSH_USER}@$target_dest"
  fi
  cmd+=("--target-host" "$target_dest")

  # Format build host argument
  if [[ -n "$BUILD_HOST" ]]; then
    local build_dest="$BUILD_HOST"
    if [[ "$build_dest" != *@* ]]; then
      build_dest="${SSH_USER}@$build_dest"
    fi
    cmd+=("--build-host" "$build_dest")
  fi

  # Add extra args passed with --
  if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    cmd+=("${EXTRA_ARGS[@]}")
  fi

  log_info "Executing: ${cmd[*]}"
  
  if "${cmd[@]}"; then
    log_success "Successfully deployed to ${host}"
    DEPLOY_STATUSES+=("SUCCESS")
    return 0
  else
    log_error "Failed deploying to ${host}"
    DEPLOY_STATUSES+=("FAILED")
    return 1
  fi
}

# Run deployment for all target hosts
errors=0
for host in "${TARGET_HOSTS[@]}"; do
  if ! deploy_host "$host"; then
    errors=$((errors + 1))
  fi
done

# Print summary table
echo -e "\n${BOLD}Deployment Summary:${NC}"
echo "--------------------------------------------------"
for i in "${!DEPLOY_HOSTS[@]}"; do
  host="${DEPLOY_HOSTS[$i]}"
  status="${DEPLOY_STATUSES[$i]}"
  color="${NC}"
  case "$status" in
    SUCCESS) color="${GREEN}" ;;
    FAILED) color="${RED}" ;;
    SKIPPED*) color="${YELLOW}" ;;
  esac
  printf "  %-20s -> %b%s%b\n" "$host" "$color" "$status" "$NC"
done
echo "--------------------------------------------------"

if [[ $errors -gt 0 ]]; then
  log_error "Deployment completed with $errors failure(s)."
  exit 1
else
  log_success "All deployments completed successfully."
fi

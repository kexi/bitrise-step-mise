#!/bin/bash
set -eo pipefail

# ==============================================================================
# Functions
# ==============================================================================

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_done() {
    echo "[DONE] $1"
}

validate_yes_no() {
    local value="$1"
    local param_name="$2"

    local is_valid=$([[ "${value}" == "yes" || "${value}" == "no" ]] && echo "true" || echo "false")
    if [[ "${is_valid}" == "false" ]]; then
        log_error "Invalid value for ${param_name}: '${value}'. Must be 'yes' or 'no'."
        exit 1
    fi
}

# ==============================================================================
# Input Validation
# ==============================================================================

log_info "Validating inputs..."

validate_yes_no "${run_trust}" "run_trust"
validate_yes_no "${run_install}" "run_install"
validate_yes_no "${use_shims}" "use_shims"

log_done "Input validation completed"

# ==============================================================================
# Install mise
# ==============================================================================

log_info "Installing mise..."

MISE_INSTALL_DIR="${HOME}/.local/bin"
MISE_SHIMS_DIR="${HOME}/.local/share/mise/shims"

# Install mise using the official installer
if [[ "${mise_version}" == "latest" ]]; then
    curl -fsSL https://mise.run | sh
else
    curl -fsSL https://mise.run | MISE_VERSION="${mise_version}" sh
fi

# Verify installation
is_install_success=$([[ -f "${MISE_INSTALL_DIR}/mise" ]] && echo "true" || echo "false")
if [[ "${is_install_success}" == "false" ]]; then
    log_error "mise installation failed: binary not found at ${MISE_INSTALL_DIR}/mise"
    exit 1
fi

log_done "mise installed successfully"

# ==============================================================================
# Set up PATH
# ==============================================================================

log_info "Setting up PATH..."

# Add mise binary directory to PATH
envman add --key PATH --value "${MISE_INSTALL_DIR}:${PATH}"

# Add shims directory to PATH if requested
should_add_shims=$([[ "${use_shims}" == "yes" ]] && echo "true" || echo "false")
if [[ "${should_add_shims}" == "true" ]]; then
    # Create shims directory if it doesn't exist
    mkdir -p "${MISE_SHIMS_DIR}"
    envman add --key PATH --value "${MISE_SHIMS_DIR}:${MISE_INSTALL_DIR}:${PATH}"
    log_info "Added mise shims directory to PATH"
fi

# Export outputs
envman add --key MISE_BIN_PATH --value "${MISE_INSTALL_DIR}/mise"
envman add --key MISE_SHIMS_PATH --value "${MISE_SHIMS_DIR}"

# Make mise available in current session
export PATH="${MISE_INSTALL_DIR}:${PATH}"

log_done "PATH setup completed"

# Show installed version
log_info "Installed mise version: $(mise --version)"

# ==============================================================================
# Run mise trust
# ==============================================================================

run_mise_trust() {
    local should_skip=$([[ "${run_trust}" != "yes" ]] && echo "true" || echo "false")
    if [[ "${should_skip}" == "true" ]]; then
        log_info "Skipping mise trust (run_trust=no)"
        return 0
    fi

    cd "${working_dir}"

    # Check if config file exists
    local has_config="false"
    if [[ -f "mise.toml" || -f ".mise.toml" || -f ".tool-versions" ]]; then
        has_config="true"
    fi

    local should_skip_no_config=$([[ "${has_config}" == "false" ]] && echo "true" || echo "false")
    if [[ "${should_skip_no_config}" == "true" ]]; then
        log_info "No mise config file found, skipping mise trust"
        return 0
    fi

    log_info "Running mise trust..."
    mise trust --all
    log_done "mise trust completed"
}

run_mise_trust

# ==============================================================================
# Run mise install
# ==============================================================================

run_mise_install() {
    local should_skip=$([[ "${run_install}" != "yes" ]] && echo "true" || echo "false")
    if [[ "${should_skip}" == "true" ]]; then
        log_info "Skipping mise install (run_install=no)"
        return 0
    fi

    cd "${working_dir}"

    # Check if config file exists
    local has_config="false"
    if [[ -f "mise.toml" || -f ".mise.toml" || -f ".tool-versions" ]]; then
        has_config="true"
    fi

    local should_skip_no_config=$([[ "${has_config}" == "false" ]] && echo "true" || echo "false")
    if [[ "${should_skip_no_config}" == "true" ]]; then
        log_info "No mise config file found, skipping mise install"
        return 0
    fi

    log_info "Running mise install..."
    mise install --yes
    log_done "mise install completed"

    # Reshim after install to ensure shims are created
    local should_reshim=$([[ "${use_shims}" == "yes" ]] && echo "true" || echo "false")
    if [[ "${should_reshim}" == "true" ]]; then
        log_info "Running mise reshim..."
        mise reshim
        log_done "mise reshim completed"
    fi
}

run_mise_install

log_done "mise step completed successfully!"

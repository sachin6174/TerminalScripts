#!/bin/bash

# Universal macOS Installer Script
# Handles DMG, PKG, ZIP, TAR, and other archive formats
# Usage: ./universal_installer.sh -f /path/to/file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Global variables
TEMP_DIR=""
MOUNTED_VOLUMES=()

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    
    # Unmount any mounted volumes
    for volume in "${MOUNTED_VOLUMES[@]}"; do
        if [[ -d "$volume" ]]; then
            log_info "Unmounting $volume"
            hdiutil detach "$volume" 2>/dev/null || true
        fi
    done
    
    # Remove temporary directory
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        log_info "Removing temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Check if running as admin for PKG installations
check_admin() {
    if [[ $EUID -ne 0 ]]; then
        log_warning "Some installations may require admin privileges"
        return 1
    fi
    return 0
}

# Create temporary directory
create_temp_dir() {
    TEMP_DIR=$(mktemp -d)
    log_info "Created temporary directory: $TEMP_DIR"
}

# Install PKG file
install_pkg() {
    local pkg_file="$1"
    log_info "Installing PKG: $pkg_file"
    
    if ! check_admin; then
        log_info "Requesting admin privileges for PKG installation..."
        sudo installer -pkg "$pkg_file" -target /
    else
        installer -pkg "$pkg_file" -target /
    fi
    
    log_success "PKG installation completed: $pkg_file"
}

# Mount and process DMG
process_dmg() {
    local dmg_file="$1"
    log_info "Processing DMG: $dmg_file"
    
    # Mount the DMG
    local mount_point=$(hdiutil attach "$dmg_file" -nobrowse -readonly | grep -E '^/dev/' | tail -1 | awk '{print $3}')
    
    if [[ -z "$mount_point" ]]; then
        log_error "Failed to mount DMG: $dmg_file"
        return 1
    fi
    
    MOUNTED_VOLUMES+=("$mount_point")
    log_info "Mounted DMG at: $mount_point"
    
    # Process contents of mounted DMG
    process_directory_contents "$mount_point"
    
    # Unmount the DMG
    hdiutil detach "$mount_point"
    MOUNTED_VOLUMES=("${MOUNTED_VOLUMES[@]/$mount_point}")
    log_success "DMG processing completed: $dmg_file"
}

# Copy .app to Applications folder
install_app() {
    local app_path="$1"
    local app_name=$(basename "$app_path")
    local dest_path="/Applications/$app_name"
    
    log_info "Installing app: $app_name"
    
    if [[ -e "$dest_path" ]]; then
        log_warning "App already exists at $dest_path, removing old version"
        rm -rf "$dest_path"
    fi
    
    cp -R "$app_path" "/Applications/"
    log_success "App installed: $dest_path"
}

# Process directory contents (for mounted DMGs or extracted archives)
process_directory_contents() {
    local dir_path="$1"
    log_info "Processing directory contents: $dir_path"
    
    # Look for .app files
    while IFS= read -r -d '' app_file; do
        install_app "$app_file"
    done < <(find "$dir_path" -name "*.app" -type d -print0)
    
    # Look for .pkg files
    while IFS= read -r -d '' pkg_file; do
        install_pkg "$pkg_file"
    done < <(find "$dir_path" -name "*.pkg" -type f -print0)
    
    # Look for nested .dmg files
    while IFS= read -r -d '' dmg_file; do
        process_dmg "$dmg_file"
    done < <(find "$dir_path" -name "*.dmg" -type f -print0)
}

# Extract archive files
extract_archive() {
    local archive_file="$1"
    local extract_dir="$TEMP_DIR/extracted"
    
    mkdir -p "$extract_dir"
    log_info "Extracting archive: $archive_file"
    
    local file_ext="${archive_file##*.}"
    file_ext=$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')
    
    case "$file_ext" in
        zip)
            unzip -q "$archive_file" -d "$extract_dir"
            ;;
        tar)
            tar -xf "$archive_file" -C "$extract_dir"
            ;;
        gz|tgz)
            if [[ "$archive_file" == *.tar.gz ]] || [[ "$archive_file" == *.tgz ]]; then
                tar -xzf "$archive_file" -C "$extract_dir"
            else
                gunzip -c "$archive_file" > "$extract_dir/$(basename "${archive_file%.*}")"
            fi
            ;;
        bz2|tbz2)
            if [[ "$archive_file" == *.tar.bz2 ]] || [[ "$archive_file" == *.tbz2 ]]; then
                tar -xjf "$archive_file" -C "$extract_dir"
            else
                bunzip2 -c "$archive_file" > "$extract_dir/$(basename "${archive_file%.*}")"
            fi
            ;;
        xz|txz)
            if [[ "$archive_file" == *.tar.xz ]] || [[ "$archive_file" == *.txz ]]; then
                tar -xJf "$archive_file" -C "$extract_dir"
            else
                xz -dc "$archive_file" > "$extract_dir/$(basename "${archive_file%.*}")"
            fi
            ;;
        7z)
            if command -v 7z >/dev/null 2>&1; then
                7z x "$archive_file" -o"$extract_dir"
            else
                log_error "7z utility not found. Please install p7zip"
                return 1
            fi
            ;;
        rar)
            if command -v unrar >/dev/null 2>&1; then
                unrar x "$archive_file" "$extract_dir/"
            else
                log_error "unrar utility not found. Please install unrar"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported archive format: $file_ext"
            return 1
            ;;
    esac
    
    log_success "Archive extracted to: $extract_dir"
    
    # Process extracted contents
    process_directory_contents "$extract_dir"
}

# Main processing function
process_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        return 1
    fi
    
    local file_ext="${file_path##*.}"
    file_ext=$(echo "$file_ext" | tr '[:upper:]' '[:lower:]')
    
    log_info "Processing file: $file_path (type: $file_ext)"
    
    case "$file_ext" in
        dmg)
            process_dmg "$file_path"
            ;;
        pkg)
            install_pkg "$file_path"
            ;;
        zip|tar|gz|tgz|bz2|tbz2|xz|txz|7z|rar)
            extract_archive "$file_path"
            ;;
        app)
            if [[ -d "$file_path" ]]; then
                install_app "$file_path"
            else
                log_error "Invalid .app bundle: $file_path"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported file type: $file_ext"
            log_info "Supported types: dmg, pkg, zip, tar, gz, tgz, bz2, tbz2, xz, txz, 7z, rar, app"
            return 1
            ;;
    esac
}

# Usage function
usage() {
    echo "Universal macOS Installer Script"
    echo "Usage: $0 -f <file_path>"
    echo ""
    echo "Supported file types:"
    echo "  - DMG files: Mount and process contents"
    echo "  - PKG files: Install directly"
    echo "  - Archives: Extract and process contents (zip, tar, gz, tgz, bz2, tbz2, xz, txz, 7z, rar)"
    echo "  - APP bundles: Copy to Applications folder"
    echo ""
    echo "The script automatically handles nested installers within archives and DMG files."
}

# Main script
main() {
    local file_path=""
    
    # Parse command line arguments
    while getopts "f:h" opt; do
        case $opt in
            f)
                file_path="$OPTARG"
                ;;
            h)
                usage
                exit 0
                ;;
            \?)
                log_error "Invalid option: -$OPTARG"
                usage
                exit 1
                ;;
        esac
    done
    
    # Check if file path is provided
    if [[ -z "$file_path" ]]; then
        log_error "File path is required"
        usage
        exit 1
    fi
    
    # Create temporary directory
    create_temp_dir
    
    # Process the file
    log_info "Starting universal installer..."
    process_file "$file_path"
    log_success "Universal installer completed successfully!"
}

# Run main function with all arguments
main "$@"
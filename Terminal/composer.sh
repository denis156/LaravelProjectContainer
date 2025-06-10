#!/bin/bash

# ===============================================
# LaravelProjectContainer - Composer Shortcuts Script
# ===============================================
# Script untuk shortcuts Composer commands
# Penggunaan: ./composer.sh [command] [arguments]
# ===============================================

# Warna untuk output Terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Directory paths
PROJECTS_DIR="/var/www/html/Projects"
CURRENT_PROJECT_FILE="/tmp/current_laravel_project"

# Helper functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${WHITE}  LaravelProjectContainer - Composer${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Get current project
get_current_project() {
    if [ -f "$CURRENT_PROJECT_FILE" ]; then
        cat "$CURRENT_PROJECT_FILE"
    else
        echo ""
    fi
}

# Execute composer command
execute_composer() {
    local project_name=$(get_current_project)
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project $project_name tidak ditemukan!"
        exit 1
    fi
    
    if [ ! -f "$project_path/composer.json" ]; then
        print_error "File composer.json tidak ditemukan di project $project_name"
        exit 1
    fi
    
    cd "$project_path"
    composer "$@"
}

# Command: install - Install dependencies
cmd_install() {
    local mode=${1:-"dev"}
    
    case "$mode" in
        "dev"|"development"|"")
            print_info "Installing development dependencies..."
            execute_composer install --prefer-dist
            ;;
        "prod"|"production")
            print_info "Installing production dependencies..."
            execute_composer install --no-dev --optimize-autoloader --no-interaction
            ;;
        "fast")
            print_info "Fast install with optimizations..."
            execute_composer install --prefer-dist --optimize-autoloader --classmap-authoritative
            ;;
        "fresh")
            print_info "Fresh install (removing vendor first)..."
            local project_name=$(get_current_project)
            local project_path="$PROJECTS_DIR/$project_name"
            cd "$project_path"
            
            if [ -d "vendor" ]; then
                print_warning "Menghapus vendor directory..."
                rm -rf vendor
            fi
            
            if [ -f "composer.lock" ]; then
                print_warning "Menghapus composer.lock..."
                rm -f composer.lock
            fi
            
            execute_composer install --prefer-dist
            ;;
        *)
            print_error "Install mode tidak dikenal: $mode"
            echo -e "${YELLOW}Available modes:${NC}"
            echo -e "• ${GREEN}dev${NC} - Development dependencies (default)"
            echo -e "• ${GREEN}prod${NC} - Production dependencies only"
            echo -e "• ${GREEN}fast${NC} - Fast install dengan optimizations"
            echo -e "• ${GREEN}fresh${NC} - Fresh install (hapus vendor/lock)"
            ;;
    esac
}

# Command: update - Update dependencies
cmd_update() {
    local target=${1:-"all"}
    
    case "$target" in
        "all"|"")
            print_info "Updating all dependencies..."
            execute_composer update --with-dependencies
            ;;
        "lock")
            print_info "Updating composer.lock file only..."
            execute_composer update --lock
            ;;
        "dry")
            print_info "Dry run update (preview changes)..."
            execute_composer update --dry-run
            ;;
        "security")
            print_info "Updating security-related packages..."
            # Check untuk security advisories
            execute_composer audit
            print_info "Updating packages with security fixes..."
            execute_composer update --with-dependencies
            ;;
        *)
            print_info "Updating specific package: $target"
            shift
            execute_composer update "$target" "$@"
            ;;
    esac
}

# Command: require - Add new package
cmd_require() {
    if [ $# -eq 0 ]; then
        print_error "Package name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./composer.sh require <package> [version] [--dev]${NC}"
        echo -e "${CYAN}Examples:${NC}"
        echo -e "  ./composer.sh require laravel/telescope"
        echo -e "  ./composer.sh require phpunit/phpunit --dev"
        echo -e "  ./composer.sh require guzzlehttp/guzzle ^7.0"
        exit 1
    fi
    
    local package=$1
    shift
    
    print_info "Adding package: $package"
    execute_composer require "$package" "$@"
    
    # Check if package was successfully installed
    if [ $? -eq 0 ]; then
        print_success "Package $package berhasil ditambahkan!"
        
        # Auto-publish config jika Laravel package
        local project_name=$(get_current_project)
        local project_path="$PROJECTS_DIR/$project_name"
        cd "$project_path"
        
        # Check untuk Laravel service providers yang perlu publish
        case "$package" in
            "laravel/telescope")
                print_info "Publishing Telescope assets..."
                php artisan telescope:install --force
                ;;
            "laravel/horizon")
                print_info "Publishing Horizon assets..."
                php artisan horizon:install
                ;;
            "laravel/sanctum")
                print_info "Publishing Sanctum config..."
                php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
                ;;
            "laravel/passport")
                print_info "Installing Passport..."
                php artisan passport:install
                ;;
            "spatie/laravel-permission")
                print_info "Publishing Permission migrations..."
                php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
                ;;
            *)
                # Generic publish attempt
                if php artisan vendor:publish --tag="$package" --dry-run 2>/dev/null | grep -q "Nothing to publish"; then
                    : # Do nothing
                else
                    print_info "Package mungkin memiliki publishable assets"
                    print_info "Jalankan: php artisan vendor:publish untuk melihat options"
                fi
                ;;
        esac
    fi
}

# Command: remove - Remove package
cmd_remove() {
    if [ $# -eq 0 ]; then
        print_error "Package name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./composer.sh remove <package> [--dev]${NC}"
        exit 1
    fi
    
    local package=$1
    shift
    
    print_warning "Menghapus package: $package"
    read -p "Apakah Anda yakin? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        execute_composer remove "$package" "$@"
        
        if [ $? -eq 0 ]; then
            print_success "Package $package berhasil dihapus!"
        fi
    else
        print_info "Penghapusan package dibatalkan"
    fi
}

# Command: search - Search packages
cmd_search() {
    if [ $# -eq 0 ]; then
        print_error "Search term harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./composer.sh search <term>${NC}"
        exit 1
    fi
    
    local term=$1
    print_info "Searching packages for: $term"
    execute_composer search "$term"
}

# Command: show - Show package information
cmd_show() {
    if [ $# -eq 0 ]; then
        print_info "Showing all installed packages..."
        execute_composer show
    else
        local package=$1
        print_info "Showing information for: $package"
        execute_composer show "$package"
    fi
}

# Command: validate - Validate composer.json
cmd_validate() {
    print_info "Validating composer.json..."
    execute_composer validate --strict
    
    if [ $? -eq 0 ]; then
        print_success "composer.json is valid!"
    fi
}

# Command: outdated - Check for outdated packages
cmd_outdated() {
    local format=${1:-"table"}
    
    case "$format" in
        "table"|"")
            print_info "Checking for outdated packages..."
            execute_composer outdated --direct
            ;;
        "json")
            print_info "Checking for outdated packages (JSON format)..."
            execute_composer outdated --direct --format=json
            ;;
        "all")
            print_info "Checking all outdated packages (including dependencies)..."
            execute_composer outdated
            ;;
        *)
            print_error "Format tidak dikenal: $format"
            echo -e "${YELLOW}Available formats:${NC}"
            echo -e "• ${GREEN}table${NC} - Table format (default)"
            echo -e "• ${GREEN}json${NC} - JSON format"
            echo -e "• ${GREEN}all${NC} - Include all dependencies"
            ;;
    esac
}

# Command: audit - Security audit
cmd_audit() {
    print_info "Running security audit..."
    execute_composer audit
    
    if [ $? -eq 0 ]; then
        print_success "No security issues found!"
    else
        print_warning "Security issues detected! Check output above."
        print_info "Gunakan './composer.sh update security' untuk fix issues"
    fi
}

# Command: dumpautoload - Regenerate autoloader
cmd_dumpautoload() {
    local optimize=${1:-""}
    
    case "$optimize" in
        "optimize"|"opt"|"-o")
            print_info "Regenerating optimized autoloader..."
            execute_composer dump-autoload --optimize
            ;;
        "classmap"|"auth"|"-a")
            print_info "Regenerating authoritative classmap..."
            execute_composer dump-autoload --optimize --classmap-authoritative
            ;;
        "apcu")
            print_info "Regenerating autoloader with APCu cache..."
            execute_composer dump-autoload --optimize --apcu
            ;;
        ""|"normal")
            print_info "Regenerating autoloader..."
            execute_composer dump-autoload
            ;;
        *)
            print_error "Optimize option tidak dikenal: $optimize"
            echo -e "${YELLOW}Available options:${NC}"
            echo -e "• ${GREEN}normal${NC} - Normal autoloader (default)"
            echo -e "• ${GREEN}optimize${NC} - Optimized autoloader"
            echo -e "• ${GREEN}classmap${NC} - Authoritative classmap"
            echo -e "• ${GREEN}apcu${NC} - APCu optimized autoloader"
            ;;
    esac
}

# Command: scripts - Show available scripts
cmd_scripts() {
    print_info "Available Composer scripts:"
    execute_composer run-script --list
}

# Command: run - Run composer script
cmd_run() {
    if [ $# -eq 0 ]; then
        print_error "Script name harus diisi!"
        print_info "Gunakan './composer.sh scripts' untuk melihat available scripts"
        exit 1
    fi
    
    local script=$1
    shift
    
    print_info "Running script: $script"
    execute_composer run-script "$script" "$@"
}

# Command: check - Check platform requirements
cmd_check() {
    print_info "Checking platform requirements..."
    execute_composer check-platform-reqs
    
    if [ $? -eq 0 ]; then
        print_success "All platform requirements satisfied!"
    fi
}

# Command: diagnose - Diagnose problems
cmd_diagnose() {
    print_info "Running Composer diagnostics..."
    execute_composer diagnose
}

# Command: status - Show package status
cmd_status() {
    print_info "Checking package modification status..."
    execute_composer status --verbose
}

# Command: licenses - Show package licenses
cmd_licenses() {
    local format=${1:-"table"}
    
    case "$format" in
        "table"|"")
            print_info "Showing package licenses..."
            execute_composer licenses
            ;;
        "json")
            print_info "Showing package licenses (JSON format)..."
            execute_composer licenses --format=json
            ;;
        *)
            print_error "Format tidak dikenal: $format"
            echo -e "${YELLOW}Available formats:${NC}"
            echo -e "• ${GREEN}table${NC} - Table format (default)"
            echo -e "• ${GREEN}json${NC} - JSON format"
            ;;
    esac
}

# Command: why - Show why package is installed
cmd_why() {
    if [ $# -eq 0 ]; then
        print_error "Package name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./composer.sh why <package>${NC}"
        exit 1
    fi
    
    local package=$1
    print_info "Checking why package '$package' is installed..."
    execute_composer why "$package"
}

# Command: suggests - Show package suggestions
cmd_suggests() {
    local verbose=${1:-""}
    
    if [ "$verbose" = "verbose" ] || [ "$verbose" = "-v" ]; then
        print_info "Showing detailed package suggestions..."
        execute_composer suggests --verbose
    else
        print_info "Showing package suggestions..."
        execute_composer suggests
    fi
}

# Command: fund - Show funding information
cmd_fund() {
    print_info "Showing package funding information..."
    execute_composer fund
}

# Command: config - Composer configuration
cmd_config() {
    local action=${1:-"list"}
    
    case "$action" in
        "list"|"")
            print_info "Showing Composer configuration..."
            execute_composer config --list
            ;;
        "global")
            shift
            print_info "Managing global Composer config..."
            execute_composer config --global "$@"
            ;;
        "repo"|"repositories")
            print_info "Showing configured repositories..."
            execute_composer config repositories
            ;;
        *)
            print_info "Setting config: $action"
            shift
            execute_composer config "$action" "$@"
            ;;
    esac
}

# Command: clear-cache - Clear Composer cache
cmd_clear_cache() {
    print_info "Clearing Composer cache..."
    execute_composer clear-cache
    
    if [ $? -eq 0 ]; then
        print_success "Composer cache cleared!"
    fi
}

# Command: self-update - Update Composer itself
cmd_self_update() {
    print_info "Updating Composer to latest version..."
    composer self-update
    
    if [ $? -eq 0 ]; then
        print_success "Composer updated successfully!"
        composer --version
    fi
}

# Command: create-project - Create new project
cmd_create_project() {
    if [ $# -lt 2 ]; then
        print_error "Package dan directory harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./composer.sh create-project <package> <directory> [version]${NC}"
        echo -e "${CYAN}Examples:${NC}"
        echo -e "  ./composer.sh create-project laravel/laravel my-app"
        echo -e "  ./composer.sh create-project laravel/laravel my-app ^11.0"
        exit 1
    fi
    
    local package=$1
    local directory=$2
    local version=${3:-""}
    
    print_info "Creating new project: $package -> $directory"
    
    cd "$PROJECTS_DIR"
    
    if [ -n "$version" ]; then
        composer create-project "$package" "$directory" "$version" --prefer-dist
    else
        composer create-project "$package" "$directory" --prefer-dist
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Project created successfully in $PROJECTS_DIR/$directory"
        print_info "Gunakan './project.sh switch $directory' untuk switch ke project ini"
    fi
}

# Command: info - Show Composer and PHP info
cmd_info() {
    print_header
    echo -e "${WHITE}Composer & PHP Information${NC}\n"
    
    # Composer version
    echo -e "${CYAN}Composer Version:${NC}"
    composer --version
    
    # PHP version
    echo -e "\n${CYAN}PHP Version:${NC}"
    php --version | head -n 1
    
    # Current project info
    local project_name=$(get_current_project)
    if [ -n "$project_name" ]; then
        echo -e "\n${CYAN}Current Project:${NC} $project_name"
        local project_path="$PROJECTS_DIR/$project_name"
        
        if [ -f "$project_path/composer.json" ]; then
            cd "$project_path"
            echo -e "${CYAN}Project Type:${NC} $(jq -r '.type // "project"' composer.json 2>/dev/null || echo "unknown")"
            echo -e "${CYAN}Description:${NC} $(jq -r '.description // "No description"' composer.json 2>/dev/null || echo "No description")"
            
            # Dependencies count
            local require_count=$(jq '.require | length' composer.json 2>/dev/null || echo "0")
            local require_dev_count=$(jq '."require-dev" | length' composer.json 2>/dev/null || echo "0")
            echo -e "${CYAN}Dependencies:${NC} $require_count production, $require_dev_count development"
        fi
    else
        echo -e "\n${YELLOW}No active project${NC}"
    fi
    
    # Platform requirements
    echo -e "\n${CYAN}Platform Requirements:${NC}"
    composer check-platform-reqs 2>/dev/null | head -n 5 || echo "Cannot check platform requirements"
}

# Command: help - Tampilkan bantuan
cmd_help() {
    print_header
    echo -e "${WHITE}Composer Shortcuts untuk Laravel${NC}\n"
    
    echo -e "${CYAN}Package Management:${NC}"
    echo -e "  ${GREEN}install [mode]${NC}        - Install dependencies"
    echo -e "  ${GREEN}update [target]${NC}       - Update dependencies"
    echo -e "  ${GREEN}require <pkg> [ver]${NC}   - Add new package"
    echo -e "  ${GREEN}remove <package>${NC}      - Remove package"
    
    echo -e "\n${CYAN}Information:${NC}"
    echo -e "  ${GREEN}show [package]${NC}        - Show package info"
    echo -e "  ${GREEN}search <term>${NC}         - Search packages"
    echo -e "  ${GREEN}outdated [format]${NC}     - Check outdated packages"
    echo -e "  ${GREEN}why <package>${NC}         - Why package is installed"
    echo -e "  ${GREEN}licenses [format]${NC}     - Show package licenses"
    
    echo -e "\n${CYAN}Maintenance:${NC}"
    echo -e "  ${GREEN}validate${NC}              - Validate composer.json"
    echo -e "  ${GREEN}audit${NC}                 - Security audit"
    echo -e "  ${GREEN}dumpautoload [opt]${NC}    - Regenerate autoloader"
    echo -e "  ${GREEN}clear-cache${NC}           - Clear Composer cache"
    
    echo -e "\n${CYAN}Scripts & Tools:${NC}"
    echo -e "  ${GREEN}scripts${NC}               - Show available scripts"
    echo -e "  ${GREEN}run <script>${NC}          - Run composer script"
    echo -e "  ${GREEN}diagnose${NC}              - Diagnose problems"
    echo -e "  ${GREEN}check${NC}                 - Check platform requirements"
    
    echo -e "\n${CYAN}Advanced:${NC}"
    echo -e "  ${GREEN}config [action]${NC}       - Composer configuration"
    echo -e "  ${GREEN}create-project${NC}        - Create new project"
    echo -e "  ${GREEN}self-update${NC}           - Update Composer"
    echo -e "  ${GREEN}info${NC}                  - Show system info"
    
    echo -e "\n${CYAN}Install Modes:${NC}"
    echo -e "  ${GREEN}dev${NC} - Development dependencies (default)"
    echo -e "  ${GREEN}prod${NC} - Production only"
    echo -e "  ${GREEN}fast${NC} - Fast install dengan optimizations"
    echo -e "  ${GREEN}fresh${NC} - Fresh install (hapus vendor/lock)"
    
    echo -e "\n${CYAN}Update Targets:${NC}"
    echo -e "  ${GREEN}all${NC} - Update semua packages (default)"
    echo -e "  ${GREEN}lock${NC} - Update lock file only"
    echo -e "  ${GREEN}dry${NC} - Dry run (preview)"
    echo -e "  ${GREEN}security${NC} - Security updates"
    echo -e "  ${GREEN}<package>${NC} - Update specific package"
    
    echo -e "\n${YELLOW}Tips:${NC}"
    echo -e "• Semua commands menggunakan current active project"
    echo -e "• Laravel packages auto-publish config saat di-require"
    echo -e "• Gunakan audit command untuk security checking"
    echo -e "• Fresh install berguna saat ada dependency conflicts"
    
    echo -e "\n${CYAN}Examples:${NC}"
    echo -e "  ./composer.sh install prod"
    echo -e "  ./composer.sh require laravel/telescope --dev"
    echo -e "  ./composer.sh update security"
    echo -e "  ./composer.sh outdated"
    echo -e "  ./composer.sh dumpautoload optimize"
}

# Command: raw - Execute raw composer command
cmd_raw() {
    if [ $# -eq 0 ]; then
        print_error "Raw composer command harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./composer.sh raw <command> [arguments]${NC}"
        exit 1
    fi
    
    print_info "Executing: composer $*"
    execute_composer "$@"
}

# Main script logic
main() {
    case "${1:-help}" in
        "install"|"i")
            shift
            cmd_install "$@"
            ;;
        "update"|"u")
            shift
            cmd_update "$@"
            ;;
        "require"|"req")
            shift
            cmd_require "$@"
            ;;
        "remove"|"rem")
            shift
            cmd_remove "$@"
            ;;
        "search")
            shift
            cmd_search "$@"
            ;;
        "show")
            shift
            cmd_show "$@"
            ;;
        "validate"|"val")
            cmd_validate
            ;;
        "outdated"|"out")
            shift
            cmd_outdated "$@"
            ;;
        "audit")
            cmd_audit
            ;;
        "dumpautoload"|"dump")
            shift
            cmd_dumpautoload "$@"
            ;;
        "scripts"|"sc")
            cmd_scripts
            ;;
        "run")
            shift
            cmd_run "$@"
            ;;
        "check")
            cmd_check
            ;;
        "diagnose"|"diag")
            cmd_diagnose
            ;;
        "status"|"stat")
            cmd_status
            ;;
        "licenses"|"lic")
            shift
            cmd_licenses "$@"
            ;;
        "why")
            shift
            cmd_why "$@"
            ;;
        "suggests"|"sug")
            shift
            cmd_suggests "$@"
            ;;
        "fund")
            cmd_fund
            ;;
        "config"|"cfg")
            shift
            cmd_config "$@"
            ;;
        "clear-cache"|"cc")
            cmd_clear_cache
            ;;
        "self-update"|"selfupdate")
            cmd_self_update
            ;;
        "create-project"|"create")
            shift
            cmd_create_project "$@"
            ;;
        "info")
            cmd_info
            ;;
        "raw")
            shift
            cmd_raw "$@"
            ;;
        "help"|"-h"|"--help"|*)
            cmd_help
            ;;
    esac
}

# Jalankan script
main "$@"
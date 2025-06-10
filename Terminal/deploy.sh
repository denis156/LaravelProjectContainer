#!/bin/bash

# ===============================================
# LaravelProjectContainer - Deployment Script
# ===============================================
# Script untuk deployment automation
# Penggunaan: ./deploy.sh [command] [arguments]
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
PROJECTS_DIR="/var/www/html/projects"
CURRENT_PROJECT_FILE="/tmp/current_laravel_project"
DEPLOY_DIR="/var/www/html/deployments"
BACKUP_DIR="/var/www/html/backups/deployments"

# Helper functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${WHITE}  LaravelProjectContainer - Deployment${NC}"
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

print_step() {
    echo -e "${PURPLE}▶ $1${NC}"
}

# Get current project
get_current_project() {
    if [ -f "$CURRENT_PROJECT_FILE" ]; then
        cat "$CURRENT_PROJECT_FILE"
    else
        echo ""
    fi
}

# Create deployment directories
ensure_deploy_dirs() {
    mkdir -p "$DEPLOY_DIR"
    mkdir -p "$BACKUP_DIR"
    chown -R www-data:www-data "$DEPLOY_DIR" "$BACKUP_DIR"
}

# Get deployment info
get_deploy_info() {
    local project_name=$1
    local environment=$2
    
    local deploy_file="$DEPLOY_DIR/${project_name}_${environment}.info"
    if [ -f "$deploy_file" ]; then
        cat "$deploy_file"
    fi
}

# Save deployment info
save_deploy_info() {
    local project_name=$1
    local environment=$2
    local version=$3
    local timestamp=$4
    
    local deploy_file="$DEPLOY_DIR/${project_name}_${environment}.info"
    
    cat > "$deploy_file" << EOF
PROJECT=$project_name
ENVIRONMENT=$environment
VERSION=$version
TIMESTAMP=$timestamp
DEPLOYED_BY=$(whoami)
DEPLOYMENT_ID=${project_name}_${environment}_${timestamp}
STATUS=deployed
EOF
}

# Pre-deployment checks
pre_deploy_checks() {
    local project_name=$1
    local environment=$2
    
    print_step "Running pre-deployment checks..."
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    # Check project exists
    if [ ! -d "$project_path" ]; then
        print_error "Project tidak ditemukan: $project_name"
        return 1
    fi
    
    # Check Laravel project
    if [ ! -f "$project_path/artisan" ]; then
        print_error "Bukan project Laravel yang valid"
        return 1
    fi
    
    cd "$project_path"
    
    # Check composer.json
    if [ ! -f "composer.json" ]; then
        print_error "composer.json tidak ditemukan"
        return 1
    fi
    
    # Check .env file
    if [ ! -f ".env" ] && [ "$environment" != "production" ]; then
        print_warning ".env file tidak ditemukan"
    fi
    
    # Check git status (if git repo)
    if [ -d ".git" ]; then
        if ! git diff --quiet HEAD; then
            print_warning "Ada uncommitted changes"
            if [ "$environment" = "production" ]; then
                print_error "Production deployment memerlukan clean git status"
                return 1
            fi
        fi
    fi
    
    # Check dependencies
    if [ ! -d "vendor" ]; then
        print_warning "Vendor directory tidak ditemukan, akan install dependencies"
    fi
    
    print_success "Pre-deployment checks passed"
    return 0
}

# Build assets
build_assets() {
    local project_name=$1
    local environment=$2
    
    print_step "Building assets..."
    
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    # Install PHP dependencies
    if [ "$environment" = "production" ]; then
        print_info "Installing production dependencies..."
        composer install --no-dev --optimize-autoloader --no-interaction
    else
        print_info "Installing development dependencies..."
        composer install --optimize-autoloader --no-interaction
    fi
    
    # Install NPM dependencies and build
    if [ -f "package.json" ]; then
        print_info "Installing NPM dependencies..."
        npm ci
        
        # Build assets based on environment
        if [ "$environment" = "production" ]; then
            if npm run --silent 2>/dev/null | grep -q "build"; then
                print_info "Building production assets..."
                npm run build
            elif npm run --silent 2>/dev/null | grep -q "production"; then
                print_info "Building production assets..."
                npm run production
            fi
        else
            if npm run --silent 2>/dev/null | grep -q "dev"; then
                print_info "Building development assets..."
                npm run dev
            fi
        fi
    fi
    
    print_success "Assets built successfully"
}

# Optimize Laravel
optimize_laravel() {
    local project_name=$1
    local environment=$2
    
    print_step "Optimizing Laravel..."
    
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    if [ "$environment" = "production" ]; then
        # Production optimizations
        print_info "Applying production optimizations..."
        php artisan config:cache
        php artisan route:cache
        php artisan view:cache
        php artisan event:cache
        
        # Optimize composer autoloader
        composer dump-autoload --optimize --classmap-authoritative
    else
        # Clear caches for development/staging
        print_info "Clearing caches..."
        php artisan config:clear
        php artisan route:clear
        php artisan view:clear
        php artisan cache:clear
    fi
    
    print_success "Laravel optimization completed"
}

# Database migration
run_migrations() {
    local project_name=$1
    local environment=$2
    local force=${3:-false}
    
    print_step "Running database migrations..."
    
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    if [ "$force" = "true" ] || [ "$environment" != "production" ]; then
        php artisan migrate --no-interaction
    else
        print_info "Production environment detected"
        read -p "Run migrations? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            php artisan migrate --no-interaction
        else
            print_warning "Migrations skipped"
        fi
    fi
    
    print_success "Database migrations completed"
}

# Restart services
restart_services() {
    local project_name=$1
    local environment=$2
    
    print_step "Restarting services..."
    
    # Restart queue workers
    php artisan queue:restart
    
    # Restart supervisor processes
    supervisorctl restart "${project_name}:*" 2>/dev/null || true
    
    # Restart FrankenPHP
    supervisorctl restart frankenphp 2>/dev/null || pkill -USR1 caddy 2>/dev/null || true
    
    print_success "Services restarted"
}

# Health check
health_check() {
    local project_name=$1
    local environment=$2
    local max_attempts=${3:-30}
    
    print_step "Running health checks..."
    
    # Get project URL
    local url="http://localhost"
    if [ -f "$PROJECTS_DIR/$project_name/.port" ]; then
        local port=$(cat "$PROJECTS_DIR/$project_name/.port")
        url="http://localhost:$port"
    fi
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null; then
            print_success "Health check passed"
            return 0
        fi
        
        print_info "Attempt $attempt/$max_attempts failed, retrying in 2s..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "Health check failed after $max_attempts attempts"
    return 1
}

# Command: deploy - Main deployment function
cmd_deploy() {
    local project_name=${1:-$(get_current_project)}
    local environment=${2:-"staging"}
    local force_migrate=${3:-false}
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./deploy.sh deploy <project> <environment> [force_migrate]${NC}"
        echo -e "${CYAN}Environments: development, staging, production${NC}"
        exit 1
    fi
    
    ensure_deploy_dirs
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local version=$(cd "$PROJECTS_DIR/$project_name" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    print_header
    echo -e "${WHITE}Deploying: $project_name${NC}"
    echo -e "${WHITE}Environment: $environment${NC}"
    echo -e "${WHITE}Version: $version${NC}"
    echo -e "${WHITE}Timestamp: $timestamp${NC}\n"
    
    # Confirmation for production
    if [ "$environment" = "production" ]; then
        print_warning "PRODUCTION DEPLOYMENT!"
        read -p "Are you sure you want to deploy to production? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_info "Deployment cancelled"
            exit 0
        fi
    fi
    
    # Create backup before deployment
    print_step "Creating pre-deployment backup..."
    ./database.sh backup "$project_name" "pre_deploy_${timestamp}"
    
    # Run deployment steps
    if ! pre_deploy_checks "$project_name" "$environment"; then
        print_error "Pre-deployment checks failed"
        exit 1
    fi
    
    build_assets "$project_name" "$environment"
    optimize_laravel "$project_name" "$environment"
    run_migrations "$project_name" "$environment" "$force_migrate"
    restart_services "$project_name" "$environment"
    
    # Health check
    if ! health_check "$project_name" "$environment"; then
        print_error "Deployment failed health check"
        print_warning "Consider rolling back"
        exit 1
    fi
    
    # Save deployment info
    save_deploy_info "$project_name" "$environment" "$version" "$timestamp"
    
    print_success "Deployment completed successfully!"
    echo -e "\n${GREEN}Deployment Summary:${NC}"
    echo -e "Project: $project_name"
    echo -e "Environment: $environment"
    echo -e "Version: $version"
    echo -e "Deployment ID: ${project_name}_${environment}_${timestamp}"
    
    # Show URL
    if [ -f "$PROJECTS_DIR/$project_name/.port" ]; then
        local port=$(cat "$PROJECTS_DIR/$project_name/.port")
        echo -e "URL: http://localhost:$port"
    fi
}

# Command: rollback - Rollback deployment
cmd_rollback() {
    local project_name=${1:-$(get_current_project)}
    local environment=${2:-"staging"}
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./deploy.sh rollback <project> <environment>${NC}"
        exit 1
    fi
    
    print_header
    print_warning "ROLLBACK DEPLOYMENT"
    echo -e "Project: $project_name"
    echo -e "Environment: $environment\n"
    
    # Get current deployment info
    local deploy_info=$(get_deploy_info "$project_name" "$environment")
    if [ -z "$deploy_info" ]; then
        print_error "No deployment info found for $project_name ($environment)"
        exit 1
    fi
    
    echo -e "${CYAN}Current deployment:${NC}"
    echo "$deploy_info" | grep -E "(VERSION|TIMESTAMP|DEPLOYMENT_ID)"
    echo
    
    read -p "Proceed with rollback? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Rollback cancelled"
        exit 0
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    print_step "Rolling back deployment..."
    
    # Git rollback (if git repo)
    if [ -d ".git" ]; then
        print_info "Rolling back to previous commit..."
        git reset --hard HEAD~1
    fi
    
    # Database rollback
    print_info "Rolling back database migrations..."
    php artisan migrate:rollback --step=1 --no-interaction
    
    # Clear caches
    print_info "Clearing caches..."
    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
    php artisan cache:clear
    
    # Restart services
    restart_services "$project_name" "$environment"
    
    # Health check
    if ! health_check "$project_name" "$environment" 15; then
        print_error "Rollback failed health check"
        exit 1
    fi
    
    # Update deployment status
    local deploy_file="$DEPLOY_DIR/${project_name}_${environment}.info"
    if [ -f "$deploy_file" ]; then
        sed -i 's/STATUS=deployed/STATUS=rolled_back/' "$deploy_file"
    fi
    
    print_success "Rollback completed successfully!"
}

# Command: status - Show deployment status
cmd_status() {
    local project_name=${1:-$(get_current_project)}
    local environment=$2
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./deploy.sh status <project> [environment]${NC}"
        exit 1
    fi
    
    print_header
    echo -e "${WHITE}Deployment Status: $project_name${NC}\n"
    
    if [ -n "$environment" ]; then
        # Show specific environment
        local deploy_info=$(get_deploy_info "$project_name" "$environment")
        if [ -n "$deploy_info" ]; then
            echo -e "${CYAN}Environment: $environment${NC}"
            echo "$deploy_info" | while IFS='=' read -r key value; do
                echo -e "  $key: $value"
            done
        else
            echo -e "${YELLOW}No deployment found for environment: $environment${NC}"
        fi
    else
        # Show all environments
        for env in development staging production; do
            local deploy_info=$(get_deploy_info "$project_name" "$env")
            if [ -n "$deploy_info" ]; then
                echo -e "${CYAN}Environment: $env${NC}"
                echo "$deploy_info" | while IFS='=' read -r key value; do
                    echo -e "  $key: $value"
                done
                echo
            fi
        done
        
        if [ ! -f "$DEPLOY_DIR/${project_name}"_*.info ]; then
            echo -e "${YELLOW}No deployments found for project: $project_name${NC}"
        fi
    fi
}

# Command: logs - Show deployment logs
cmd_logs() {
    local project_name=${1:-$(get_current_project)}
    local environment=${2:-"staging"}
    local lines=${3:-50}
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./deploy.sh logs <project> [environment] [lines]${NC}"
        exit 1
    fi
    
    print_info "Deployment logs untuk $project_name ($environment):"
    
    # Check various log sources
    local project_path="$PROJECTS_DIR/$project_name"
    
    # Laravel logs
    if [ -f "$project_path/storage/logs/laravel.log" ]; then
        echo -e "\n${CYAN}=== Laravel Logs (last $lines lines) ===${NC}"
        tail -n "$lines" "$project_path/storage/logs/laravel.log"
    fi
    
    # Supervisor logs
    local worker_log="/var/log/laravel/${project_name}-worker.log"
    if [ -f "$worker_log" ]; then
        echo -e "\n${CYAN}=== Worker Logs (last $lines lines) ===${NC}"
        tail -n "$lines" "$worker_log"
    fi
    
    # Web server logs
    if [ -f "$project_path/.port" ]; then
        local port=$(cat "$project_path/.port")
        local access_log="/var/log/laravel/dev_${port}.log"
        if [ -f "$access_log" ]; then
            echo -e "\n${CYAN}=== Access Logs (last $lines lines) ===${NC}"
            tail -n "$lines" "$access_log"
        fi
    fi
}

# Command: history - Show deployment history
cmd_history() {
    local project_name=${1:-$(get_current_project)}
    local environment=$2
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./deploy.sh history <project> [environment]${NC}"
        exit 1
    fi
    
    print_header
    echo -e "${WHITE}Deployment History: $project_name${NC}\n"
    
    # Show deployment files
    if [ -n "$environment" ]; then
        ls -la "$DEPLOY_DIR/${project_name}_${environment}"*.info 2>/dev/null || echo "No deployment history found"
    else
        ls -la "$DEPLOY_DIR/${project_name}"_*.info 2>/dev/null || echo "No deployment history found"
    fi
    
    # Show backup files
    echo -e "\n${CYAN}Available Backups:${NC}"
    ls -la "$BACKUP_DIR"/*"${project_name}"*.sql.gz 2>/dev/null || echo "No backups found"
}

# Command: cleanup - Cleanup old deployments
cmd_cleanup() {
    local project_name=${1:-$(get_current_project)}
    local keep_count=${2:-5}
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./deploy.sh cleanup <project> [keep_count]${NC}"
        exit 1
    fi
    
    print_info "Cleaning up old deployments for $project_name (keeping latest $keep_count)..."
    
    # Cleanup deployment info files
    local deploy_files=($(ls -t "$DEPLOY_DIR/${project_name}"_*.info 2>/dev/null))
    local total_files=${#deploy_files[@]}
    
    if [ $total_files -gt $keep_count ]; then
        local files_to_delete=$((total_files - keep_count))
        print_info "Removing $files_to_delete old deployment info files..."
        
        for ((i=$keep_count; i<$total_files; i++)); do
            rm -f "${deploy_files[$i]}"
            print_info "Removed: $(basename "${deploy_files[$i]}")"
        done
    fi
    
    # Cleanup backup files
    local backup_files=($(ls -t "$BACKUP_DIR"/*"${project_name}"*.sql.gz 2>/dev/null))
    local total_backups=${#backup_files[@]}
    
    if [ $total_backups -gt $keep_count ]; then
        local backups_to_delete=$((total_backups - keep_count))
        print_info "Removing $backups_to_delete old backup files..."
        
        for ((i=$keep_count; i<$total_backups; i++)); do
            rm -f "${backup_files[$i]}"
            print_info "Removed: $(basename "${backup_files[$i]}")"
        done
    fi
    
    print_success "Cleanup completed!"
}

# Command: config - Show/set deployment configuration
cmd_config() {
    local action=${1:-"show"}
    local project_name=${2:-$(get_current_project)}
    
    case "$action" in
        "show")
            if [ -z "$project_name" ]; then
                print_error "Project name harus diisi!"
                exit 1
            fi
            
            print_header
            echo -e "${WHITE}Deployment Configuration: $project_name${NC}\n"
            
            local project_path="$PROJECTS_DIR/$project_name"
            
            # Show git info
            if [ -d "$project_path/.git" ]; then
                cd "$project_path"
                echo -e "${CYAN}Git Information:${NC}"
                echo -e "  Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
                echo -e "  Latest commit: $(git log -1 --oneline 2>/dev/null || echo 'unknown')"
                echo -e "  Remote origin: $(git remote get-url origin 2>/dev/null || echo 'none')"
                echo
            fi
            
            # Show Laravel info
            if [ -f "$project_path/artisan" ]; then
                cd "$project_path"
                echo -e "${CYAN}Laravel Information:${NC}"
                echo -e "  Version: $(php artisan --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo 'unknown')"
                echo -e "  Environment: $(grep 'APP_ENV=' .env 2>/dev/null | cut -d'=' -f2 || echo 'unknown')"
                echo -e "  Debug mode: $(grep 'APP_DEBUG=' .env 2>/dev/null | cut -d'=' -f2 || echo 'unknown')"
                echo
            fi
            
            # Show dependencies
            if [ -f "$project_path/composer.json" ]; then
                cd "$project_path"
                echo -e "${CYAN}Dependencies:${NC}"
                echo -e "  PHP packages: $(jq '.require | length' composer.json 2>/dev/null || echo 'unknown')"
                echo -e "  Dev packages: $(jq '."require-dev" | length' composer.json 2>/dev/null || echo 'unknown')"
                
                if [ -f "package.json" ]; then
                    echo -e "  NPM packages: $(jq '.dependencies | length' package.json 2>/dev/null || echo 'unknown')"
                    echo -e "  NPM dev packages: $(jq '.devDependencies | length' package.json 2>/dev/null || echo 'unknown')"
                fi
            fi
            ;;
        *)
            print_error "Config action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions: show${NC}"
            ;;
    esac
}

# Command: help - Tampilkan bantuan
cmd_help() {
    print_header
    echo -e "${WHITE}Deployment Management Commands${NC}\n"
    
    echo -e "${CYAN}Main Operations:${NC}"
    echo -e "  ${GREEN}deploy <project> <env> [force]${NC}  - Deploy project"
    echo -e "  ${GREEN}rollback <project> <env>${NC}        - Rollback deployment"
    echo -e "  ${GREEN}status <project> [env]${NC}          - Show deployment status"
    
    echo -e "\n${CYAN}Monitoring:${NC}"
    echo -e "  ${GREEN}logs <project> [env] [lines]${NC}    - Show deployment logs"
    echo -e "  ${GREEN}history <project> [env]${NC}         - Show deployment history"
    
    echo -e "\n${CYAN}Maintenance:${NC}"
    echo -e "  ${GREEN}cleanup <project> [keep]${NC}        - Cleanup old deployments"
    echo -e "  ${GREEN}config show <project>${NC}           - Show deployment config"
    
    echo -e "\n${CYAN}Environments:${NC}"
    echo -e "  ${GREEN}development${NC} - Local development"
    echo -e "  ${GREEN}staging${NC} - Staging environment (default)"
    echo -e "  ${GREEN}production${NC} - Production environment"
    
    echo -e "\n${CYAN}Deployment Process:${NC}"
    echo -e "1. Pre-deployment checks"
    echo -e "2. Create backup"
    echo -e "3. Build assets"
    echo -e "4. Optimize Laravel"
    echo -e "5. Run migrations"
    echo -e "6. Restart services"
    echo -e "7. Health check"
    echo -e "8. Save deployment info"
    
    echo -e "\n${YELLOW}Tips:${NC}"
    echo -e "• Production deployments require clean git status"
    echo -e "• Automatic backups dibuat sebelum deployment"
    echo -e "• Health checks memastikan deployment sukses"
    echo -e "• Use force parameter untuk skip migration confirmations"
    
    echo -e "\n${CYAN}Examples:${NC}"
    echo -e "  ./deploy.sh deploy myapp staging"
    echo -e "  ./deploy.sh deploy myapp production true"
    echo -e "  ./deploy.sh rollback myapp production"
    echo -e "  ./deploy.sh status myapp"
    echo -e "  ./deploy.sh logs myapp staging 100"
    echo -e "  ./deploy.sh cleanup myapp 3"
}

# Main script logic
main() {
    case "${1:-help}" in
        "deploy")
            shift
            cmd_deploy "$@"
            ;;
        "rollback"|"rb")
            shift
            cmd_rollback "$@"
            ;;
        "status"|"st")
            shift
            cmd_status "$@"
            ;;
        "logs")
            shift
            cmd_logs "$@"
            ;;
        "history"|"hist")
            shift
            cmd_history "$@"
            ;;
        "cleanup"|"clean")
            shift
            cmd_cleanup "$@"
            ;;
        "config"|"cfg")
            shift
            cmd_config "$@"
            ;;
        "help"|"-h"|"--help"|*)
            cmd_help
            ;;
    esac
}

# Jalankan script
main "$@"
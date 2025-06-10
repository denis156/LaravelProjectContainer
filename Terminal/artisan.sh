#!/bin/bash

# ===============================================
# LaravelProjectContainer - Artisan Shortcuts Script
# ===============================================
# Script untuk shortcuts Laravel Artisan commands
# Penggunaan: ./artisan.sh [command] [arguments]
# ===============================================

# Warna untuk output terminal
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
    echo -e "${WHITE}  LaravelProjectContainer - Artisan${NC}"
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

# Execute artisan command
execute_artisan() {
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
    
    if [ ! -f "$project_path/artisan" ]; then
        print_error "File artisan tidak ditemukan di project $project_name"
        exit 1
    fi
    
    cd "$project_path"
    php artisan "$@"
}

# Command: migrate - Database migrations
cmd_migrate() {
    local action=${1:-"run"}
    
    case "$action" in
        "run"|"")
            print_info "Running database migrations..."
            execute_artisan migrate --no-interaction
            ;;
        "fresh")
            print_warning "Ini akan menghapus semua data dan menjalankan ulang migrasi!"
            read -p "Apakah Anda yakin? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                execute_artisan migrate:fresh --seed --no-interaction
            else
                print_info "Fresh migration dibatalkan"
            fi
            ;;
        "rollback")
            local steps=${2:-1}
            print_warning "Rolling back $steps migration(s)..."
            execute_artisan migrate:rollback --step="$steps" --no-interaction
            ;;
        "reset")
            print_warning "Ini akan rollback semua migrations!"
            read -p "Apakah Anda yakin? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                execute_artisan migrate:reset --no-interaction
            else
                print_info "Reset migration dibatalkan"
            fi
            ;;
        "status")
            print_info "Checking migration status..."
            execute_artisan migrate:status
            ;;
        "install")
            print_info "Installing migration table..."
            execute_artisan migrate:install
            ;;
        *)
            print_error "Migration action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions:${NC}"
            echo -e "• ${GREEN}run${NC} - Jalankan migrations"
            echo -e "• ${GREEN}fresh${NC} - Fresh migrate dengan seed"
            echo -e "• ${GREEN}rollback [steps]${NC} - Rollback migrations"
            echo -e "• ${GREEN}reset${NC} - Reset semua migrations"
            echo -e "• ${GREEN}status${NC} - Lihat status migrations"
            echo -e "• ${GREEN}install${NC} - Install migration table"
            ;;
    esac
}

# Command: seed - Database seeding
cmd_seed() {
    local seeder=${1:-""}
    
    if [ -z "$seeder" ]; then
        print_info "Running all database seeders..."
        execute_artisan db:seed --no-interaction
    else
        print_info "Running seeder: $seeder"
        execute_artisan db:seed --class="$seeder" --no-interaction
    fi
}

# Command: make - Generate Laravel files
cmd_make() {
    local type=$1
    local name=$2
    
    if [ -z "$type" ] || [ -z "$name" ]; then
        print_error "Type dan name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./artisan.sh make <type> <name> [options]${NC}"
        cmd_make_help
        exit 1
    fi
    
    case "$type" in
        "model"|"m")
            print_info "Creating model: $name"
            shift 2
            execute_artisan make:model "$name" "$@"
            ;;
        "controller"|"c")
            print_info "Creating controller: $name"
            shift 2
            execute_artisan make:controller "$name" "$@"
            ;;
        "migration"|"mig")
            print_info "Creating migration: $name"
            shift 2
            execute_artisan make:migration "$name" "$@"
            ;;
        "seeder"|"s")
            print_info "Creating seeder: $name"
            shift 2
            execute_artisan make:seeder "$name" "$@"
            ;;
        "factory"|"f")
            print_info "Creating factory: $name"
            shift 2
            execute_artisan make:factory "$name" "$@"
            ;;
        "middleware"|"mid")
            print_info "Creating middleware: $name"
            shift 2
            execute_artisan make:middleware "$name" "$@"
            ;;
        "request"|"req")
            print_info "Creating request: $name"
            shift 2
            execute_artisan make:request "$name" "$@"
            ;;
        "resource"|"res")
            print_info "Creating resource: $name"
            shift 2
            execute_artisan make:resource "$name" "$@"
            ;;
        "mail")
            print_info "Creating mail: $name"
            shift 2
            execute_artisan make:mail "$name" "$@"
            ;;
        "notification"|"notif")
            print_info "Creating notification: $name"
            shift 2
            execute_artisan make:notification "$name" "$@"
            ;;
        "job")
            print_info "Creating job: $name"
            shift 2
            execute_artisan make:job "$name" "$@"
            ;;
        "event")
            print_info "Creating event: $name"
            shift 2
            execute_artisan make:event "$name" "$@"
            ;;
        "listener")
            print_info "Creating listener: $name"
            shift 2
            execute_artisan make:listener "$name" "$@"
            ;;
        "command"|"cmd")
            print_info "Creating command: $name"
            shift 2
            execute_artisan make:command "$name" "$@"
            ;;
        "provider")
            print_info "Creating provider: $name"
            shift 2
            execute_artisan make:provider "$name" "$@"
            ;;
        "test")
            print_info "Creating test: $name"
            shift 2
            execute_artisan make:test "$name" "$@"
            ;;
        "component"|"comp")
            print_info "Creating component: $name"
            shift 2
            execute_artisan make:component "$name" "$@"
            ;;
        "policy")
            print_info "Creating policy: $name"
            shift 2
            execute_artisan make:policy "$name" "$@"
            ;;
        "rule")
            print_info "Creating rule: $name"
            shift 2
            execute_artisan make:rule "$name" "$@"
            ;;
        "cast")
            print_info "Creating cast: $name"
            shift 2
            execute_artisan make:cast "$name" "$@"
            ;;
        "channel")
            print_info "Creating channel: $name"
            shift 2
            execute_artisan make:channel "$name" "$@"
            ;;
        "exception")
            print_info "Creating exception: $name"
            shift 2
            execute_artisan make:exception "$name" "$@"
            ;;
        "observer")
            print_info "Creating observer: $name"
            shift 2
            execute_artisan make:observer "$name" "$@"
            ;;
        "scope")
            print_info "Creating scope: $name"
            shift 2
            execute_artisan make:scope "$name" "$@"
            ;;
        *)
            print_error "Make type tidak dikenal: $type"
            cmd_make_help
            ;;
    esac
}

# Helper untuk make command
cmd_make_help() {
    echo -e "\n${CYAN}Available make types:${NC}"
    echo -e "${GREEN}Core:${NC}"
    echo -e "  model (m), controller (c), migration (mig), seeder (s)"
    echo -e "  factory (f), middleware (mid), request (req), resource (res)"
    echo -e "\n${GREEN}Communication:${NC}"
    echo -e "  mail, notification (notif), job, event, listener"
    echo -e "\n${GREEN}System:${NC}"
    echo -e "  command (cmd), provider, test, component (comp)"
    echo -e "  policy, rule, cast, channel, exception, observer, scope"
    
    echo -e "\n${CYAN}Common combinations:${NC}"
    echo -e "  ./artisan.sh make model User -mcr    # Model + Migration + Controller + Resource"
    echo -e "  ./artisan.sh make controller UserController --resource"
    echo -e "  ./artisan.sh make migration create_users_table --create=users"
}

# Command: queue - Queue management
cmd_queue() {
    local action=${1:-"work"}
    
    case "$action" in
        "work"|"")
            print_info "Starting queue worker..."
            execute_artisan queue:work --verbose --tries=3 --timeout=90
            ;;
        "listen")
            print_info "Starting queue listener..."
            execute_artisan queue:listen --verbose --tries=3 --timeout=90
            ;;
        "restart")
            print_info "Restarting queue workers..."
            execute_artisan queue:restart
            ;;
        "retry")
            local job_id=${2:-"all"}
            if [ "$job_id" = "all" ]; then
                print_info "Retrying all failed jobs..."
                execute_artisan queue:retry all
            else
                print_info "Retrying job: $job_id"
                execute_artisan queue:retry "$job_id"
            fi
            ;;
        "failed")
            print_info "Listing failed jobs..."
            execute_artisan queue:failed
            ;;
        "flush")
            print_warning "Ini akan menghapus semua failed jobs!"
            read -p "Apakah Anda yakin? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                execute_artisan queue:flush
            else
                print_info "Flush failed jobs dibatalkan"
            fi
            ;;
        "forget")
            local job_id=$2
            if [ -z "$job_id" ]; then
                print_error "Job ID harus diisi untuk forget command"
                exit 1
            fi
            print_info "Forgetting failed job: $job_id"
            execute_artisan queue:forget "$job_id"
            ;;
        "clear")
            local queue_name=${2:-"default"}
            print_warning "Ini akan menghapus semua jobs dari queue: $queue_name"
            read -p "Apakah Anda yakin? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                execute_artisan queue:clear "$queue_name"
            else
                print_info "Clear queue dibatalkan"
            fi
            ;;
        "table")
            print_info "Creating queue table..."
            execute_artisan queue:table
            ;;
        "failed-table")
            print_info "Creating failed jobs table..."
            execute_artisan queue:failed-table
            ;;
        "batches-table")
            print_info "Creating job batches table..."
            execute_artisan queue:batches-table
            ;;
        *)
            print_error "Queue action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions:${NC}"
            echo -e "• ${GREEN}work${NC} - Start queue worker"
            echo -e "• ${GREEN}listen${NC} - Start queue listener"
            echo -e "• ${GREEN}restart${NC} - Restart queue workers"
            echo -e "• ${GREEN}retry [job_id|all]${NC} - Retry failed jobs"
            echo -e "• ${GREEN}failed${NC} - List failed jobs"
            echo -e "• ${GREEN}flush${NC} - Delete all failed jobs"
            echo -e "• ${GREEN}forget <job_id>${NC} - Forget specific failed job"
            echo -e "• ${GREEN}clear [queue]${NC} - Clear queue"
            echo -e "• ${GREEN}table${NC} - Create queue table"
            echo -e "• ${GREEN}failed-table${NC} - Create failed jobs table"
            ;;
    esac
}

# Command: cache - Cache management
cmd_cache() {
    local action=${1:-"clear"}
    
    case "$action" in
        "clear"|"")
            print_info "Clearing application cache..."
            execute_artisan cache:clear
            ;;
        "config")
            print_info "Clearing config cache..."
            execute_artisan config:clear
            ;;
        "route")
            print_info "Clearing route cache..."
            execute_artisan route:clear
            ;;
        "view")
            print_info "Clearing view cache..."
            execute_artisan view:clear
            ;;
        "event")
            print_info "Clearing event cache..."
            execute_artisan event:clear
            ;;
        "all")
            print_info "Clearing all caches..."
            execute_artisan cache:clear
            execute_artisan config:clear
            execute_artisan route:clear
            execute_artisan view:clear
            execute_artisan event:clear
            print_success "Semua cache berhasil dihapus!"
            ;;
        "optimize")
            print_info "Optimizing application..."
            execute_artisan config:cache
            execute_artisan route:cache
            execute_artisan view:cache
            execute_artisan event:cache
            print_success "Aplikasi berhasil dioptimasi!"
            ;;
        "forget")
            local key=$2
            if [ -z "$key" ]; then
                print_error "Cache key harus diisi"
                exit 1
            fi
            print_info "Forgetting cache key: $key"
            execute_artisan cache:forget "$key"
            ;;
        "table")
            print_info "Creating cache table..."
            execute_artisan cache:table
            ;;
        *)
            print_error "Cache action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions:${NC}"
            echo -e "• ${GREEN}clear${NC} - Clear application cache"
            echo -e "• ${GREEN}config${NC} - Clear config cache"
            echo -e "• ${GREEN}route${NC} - Clear route cache"
            echo -e "• ${GREEN}view${NC} - Clear view cache"
            echo -e "• ${GREEN}event${NC} - Clear event cache"
            echo -e "• ${GREEN}all${NC} - Clear all caches"
            echo -e "• ${GREEN}optimize${NC} - Cache untuk production"
            echo -e "• ${GREEN}forget <key>${NC} - Forget specific cache key"
            echo -e "• ${GREEN}table${NC} - Create cache table"
            ;;
    esac
}

# Command: serve - Development server
cmd_serve() {
    local host=${1:-"0.0.0.0"}
    local port=${2:-"8000"}
    
    print_info "Starting Laravel development server..."
    print_info "Host: $host"
    print_info "Port: $port"
    print_info "URL: http://$host:$port"
    print_warning "Tekan Ctrl+C untuk stop server"
    
    execute_artisan serve --host="$host" --port="$port"
}

# Command: tinker - Laravel REPL
cmd_tinker() {
    print_info "Starting Laravel Tinker..."
    print_info "Ketik 'exit' untuk keluar"
    execute_artisan tinker
}

# Command: route - Route management
cmd_route() {
    local action=${1:-"list"}
    
    case "$action" in
        "list"|"")
            print_info "Listing all routes..."
            execute_artisan route:list
            ;;
        "clear")
            print_info "Clearing route cache..."
            execute_artisan route:clear
            ;;
        "cache")
            print_info "Caching routes..."
            execute_artisan route:cache
            ;;
        *)
            print_error "Route action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions:${NC}"
            echo -e "• ${GREEN}list${NC} - List semua routes"
            echo -e "• ${GREEN}clear${NC} - Clear route cache"
            echo -e "• ${GREEN}cache${NC} - Cache routes"
            ;;
    esac
}

# Command: schedule - Task scheduler
cmd_schedule() {
    local action=${1:-"run"}
    
    case "$action" in
        "run"|"")
            print_info "Running scheduled tasks..."
            execute_artisan schedule:run --verbose
            ;;
        "list")
            print_info "Listing scheduled tasks..."
            execute_artisan schedule:list
            ;;
        "work")
            print_info "Starting schedule worker..."
            execute_artisan schedule:work --verbose
            ;;
        "test")
            print_info "Testing scheduled tasks..."
            execute_artisan schedule:test
            ;;
        *)
            print_error "Schedule action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions:${NC}"
            echo -e "• ${GREEN}run${NC} - Run scheduled tasks"
            echo -e "• ${GREEN}list${NC} - List scheduled tasks"
            echo -e "• ${GREEN}work${NC} - Start schedule worker"
            echo -e "• ${GREEN}test${NC} - Test scheduled tasks"
            ;;
    esac
}

# Command: storage - Storage management
cmd_storage() {
    local action=${1:-"link"}
    
    case "$action" in
        "link"|"")
            print_info "Creating storage link..."
            execute_artisan storage:link
            ;;
        "unlink")
            print_info "Unlinking storage..."
            execute_artisan storage:unlink
            ;;
        *)
            print_error "Storage action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions:${NC}"
            echo -e "• ${GREEN}link${NC} - Create storage link"
            echo -e "• ${GREEN}unlink${NC} - Remove storage link"
            ;;
    esac
}

# Command: key - Application key management
cmd_key() {
    local action=${1:-"generate"}
    
    case "$action" in
        "generate"|"")
            print_info "Generating application key..."
            execute_artisan key:generate
            ;;
        *)
            print_error "Key action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions:${NC}"
            echo -e "• ${GREEN}generate${NC} - Generate application key"
            ;;
    esac
}

# Command: config - Configuration management
cmd_config() {
    local action=${1:-"show"}
    
    case "$action" in
        "show"|"")
            print_info "Showing configuration..."
            execute_artisan config:show
            ;;
        "clear")
            print_info "Clearing config cache..."
            execute_artisan config:clear
            ;;
        "cache")
            print_info "Caching configuration..."
            execute_artisan config:cache
            ;;
        "publish")
            local provider=$2
            if [ -z "$provider" ]; then
                print_info "Publishing all vendor configs..."
                execute_artisan vendor:publish --all
            else
                print_info "Publishing config for: $provider"
                execute_artisan vendor:publish --provider="$provider"
            fi
            ;;
        *)
            print_error "Config action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions:${NC}"
            echo -e "• ${GREEN}show${NC} - Show configuration"
            echo -e "• ${GREEN}clear${NC} - Clear config cache"
            echo -e "• ${GREEN}cache${NC} - Cache configuration"
            echo -e "• ${GREEN}publish [provider]${NC} - Publish vendor configs"
            ;;
    esac
}

# Command: optimize - Application optimization
cmd_optimize() {
    print_info "Optimizing application for production..."
    
    execute_artisan config:cache
    execute_artisan route:cache
    execute_artisan view:cache
    execute_artisan event:cache
    
    print_success "Application berhasil dioptimasi!"
}

# Command: down - Maintenance mode
cmd_down() {
    local message=${1:-"Aplikasi sedang dalam maintenance"}
    local retry=${2:-60}
    
    print_warning "Mengaktifkan maintenance mode..."
    execute_artisan down --message="$message" --retry="$retry"
}

# Command: up - Disable maintenance mode
cmd_up() {
    print_info "Menonaktifkan maintenance mode..."
    execute_artisan up
}

# Command: inspire - Get inspired
cmd_inspire() {
    execute_artisan inspire
}

# Command: about - Application information
cmd_about() {
    execute_artisan about
}

# Command: help - Tampilkan bantuan
cmd_help() {
    print_header
    echo -e "${WHITE}Laravel Artisan Shortcuts${NC}\n"
    
    echo -e "${CYAN}Database:${NC}"
    echo -e "  ${GREEN}migrate [action]${NC}      - Database migrations"
    echo -e "  ${GREEN}seed [seeder]${NC}         - Database seeding"
    
    echo -e "\n${CYAN}Generation:${NC}"
    echo -e "  ${GREEN}make <type> <name>${NC}    - Generate Laravel files"
    
    echo -e "\n${CYAN}Queue:${NC}"
    echo -e "  ${GREEN}queue [action]${NC}        - Queue management"
    
    echo -e "\n${CYAN}Cache:${NC}"
    echo -e "  ${GREEN}cache [action]${NC}        - Cache management"
    
    echo -e "\n${CYAN}Development:${NC}"
    echo -e "  ${GREEN}serve [host] [port]${NC}   - Development server"
    echo -e "  ${GREEN}tinker${NC}                - Laravel REPL"
    
    echo -e "\n${CYAN}Routes:${NC}"
    echo -e "  ${GREEN}route [action]${NC}        - Route management"
    
    echo -e "\n${CYAN}Scheduler:${NC}"
    echo -e "  ${GREEN}schedule [action]${NC}     - Task scheduler"
    
    echo -e "\n${CYAN}System:${NC}"
    echo -e "  ${GREEN}storage [action]${NC}      - Storage management"
    echo -e "  ${GREEN}key [action]${NC}          - Application key"
    echo -e "  ${GREEN}config [action]${NC}       - Configuration"
    echo -e "  ${GREEN}optimize${NC}              - Optimize for production"
    
    echo -e "\n${CYAN}Maintenance:${NC}"
    echo -e "  ${GREEN}down [message]${NC}        - Enable maintenance mode"
    echo -e "  ${GREEN}up${NC}                    - Disable maintenance mode"
    
    echo -e "\n${CYAN}Info:${NC}"
    echo -e "  ${GREEN}about${NC}                 - Application information"
    echo -e "  ${GREEN}inspire${NC}               - Get inspired"
    
    echo -e "\n${YELLOW}Tips:${NC}"
    echo -e "• Semua commands menggunakan current active project"
    echo -e "• Gunakan './project.sh switch nama_project' untuk change project"
    echo -e "• Untuk detail options, gunakan command tanpa parameter"
    
    echo -e "\n${CYAN}Examples:${NC}"
    echo -e "  ./artisan.sh migrate fresh"
    echo -e "  ./artisan.sh make model User -mcr"
    echo -e "  ./artisan.sh queue work"
    echo -e "  ./artisan.sh cache all"
    echo -e "  ./artisan.sh serve 0.0.0.0 8080"
}

# Command: raw - Execute raw artisan command
cmd_raw() {
    if [ $# -eq 0 ]; then
        print_error "Raw artisan command harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./artisan.sh raw <command> [arguments]${NC}"
        exit 1
    fi
    
    print_info "Executing: php artisan $*"
    execute_artisan "$@"
}

# Main script logic
main() {
    case "${1:-help}" in
        "migrate"|"mig")
            shift
            cmd_migrate "$@"
            ;;
        "seed")
            shift
            cmd_seed "$@"
            ;;
        "make")
            shift
            cmd_make "$@"
            ;;
        "queue"|"q")
            shift
            cmd_queue "$@"
            ;;
        "cache")
            shift
            cmd_cache "$@"
            ;;
        "serve")
            shift
            cmd_serve "$@"
            ;;
        "tinker"|"t")
            cmd_tinker
            ;;
        "route"|"r")
            shift
            cmd_route "$@"
            ;;
        "schedule"|"sch")
            shift
            cmd_schedule "$@"
            ;;
        "storage"|"stor")
            shift
            cmd_storage "$@"
            ;;
        "key")
            shift
            cmd_key "$@"
            ;;
        "config"|"cfg")
            shift
            cmd_config "$@"
            ;;
        "optimize"|"opt")
            cmd_optimize
            ;;
        "down")
            shift
            cmd_down "$@"
            ;;
        "up")
            cmd_up
            ;;
        "inspire")
            cmd_inspire
            ;;
        "about")
            cmd_about
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
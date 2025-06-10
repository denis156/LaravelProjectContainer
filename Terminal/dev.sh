#!/bin/bash

# ===============================================
# LaravelProjectContainer - Development Workflow Script
# ===============================================
# Script untuk mengelola development workflow
# Penggunaan: ./dev.sh [command] [arguments]
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
LOG_DIR="/var/log/laravel"

# Helper functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${WHITE}  LaravelProjectContainer - Development${NC}"
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

# Check if project exists
check_project_exists() {
    local project_name=$1
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project $project_name tidak ditemukan!"
        print_info "Gunakan './project.sh list' untuk melihat daftar project"
        exit 1
    fi
}

# Command: start - Start development environment
cmd_start() {
    local project_name=$(get_current_project)
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    print_header
    print_info "Starting development environment untuk project: $project_name"
    
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    # Start supervisor processes
    print_info "Starting supervisor processes..."
    supervisorctl start "${project_name}:*"
    
    # Check if .env exists
    if [ ! -f ".env" ]; then
        print_warning ".env file tidak ditemukan, membuat dari .env.example..."
        if [ -f ".env.example" ]; then
            cp .env.example .env
            php artisan key:generate --no-interaction
        fi
    fi
    
    # Install/update dependencies jika diperlukan
    if [ ! -d "vendor" ] || [ "composer.lock" -nt "vendor/autoload.php" ]; then
        print_info "Installing/updating Composer dependencies..."
        composer install
    fi
    
    # Install NPM dependencies jika diperlukan
    if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        print_info "Installing NPM dependencies..."
        npm install
    fi
    
    # Run migrations jika diperlukan
    print_info "Checking database migrations..."
    php artisan migrate:status --no-interaction 2>/dev/null || php artisan migrate --no-interaction
    
    # Clear dan cache config untuk development
    print_info "Optimizing for development..."
    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
    php artisan cache:clear
    
    # Start file watcher untuk hot reload
    if command -v inotifywait > /dev/null; then
        print_info "Starting file watcher untuk hot reload..."
        nohup bash -c "
            while inotifywait -r -e modify,create,delete --exclude '(vendor|node_modules|\.git|storage/logs)' $project_path; do
                echo '[$(date)] File changed, clearing cache...' >> $LOG_DIR/${project_name}-watcher.log
                cd $project_path
                php artisan config:clear > /dev/null 2>&1
                php artisan route:clear > /dev/null 2>&1
                php artisan view:clear > /dev/null 2>&1
            done
        " > /dev/null 2>&1 &
        echo $! > "/tmp/${project_name}_watcher.pid"
    fi
    
    # Get project port
    local port=""
    if [ -f "$project_path/.port" ]; then
        port=$(cat "$project_path/.port")
    fi
    
    print_success "Development environment berhasil distart!"
    echo -e "\n${GREEN}Project Information:${NC}"
    echo -e "📁 Project: $project_name"
    echo -e "📂 Path: $project_path"
    if [ -n "$port" ]; then
        echo -e "🌐 Port: $port"
        echo -e "🔗 URL: http://localhost:$port"
    fi
    
    echo -e "\n${GREEN}Available Commands:${NC}"
    echo -e "• ${CYAN}./dev.sh open${NC} - Buka project di browser"
    echo -e "• ${CYAN}./dev.sh logs${NC} - Lihat real-time logs"
    echo -e "• ${CYAN}./dev.sh restart${NC} - Restart semua services"
    echo -e "• ${CYAN}./dev.sh stop${NC} - Stop development environment"
}

# Command: open - Buka project di browser
cmd_open() {
    local project_name=$(get_current_project)
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ -f "$project_path/.port" ]; then
        local port=$(cat "$project_path/.port")
        local url="http://localhost:$port"
        
        print_info "Membuka $project_name di browser..."
        print_info "URL: $url"
        
        # Health check sebelum membuka browser
        if curl -f -s "$url" > /dev/null; then
            print_success "Server berjalan dengan baik"
        else
            print_warning "Server mungkin belum ready, tetap membuka browser..."
        fi
        
        # Try to open browser
        if command -v xdg-open > /dev/null; then
            xdg-open "$url" 2>/dev/null &
        elif command -v open > /dev/null; then
            open "$url" 2>/dev/null &
        elif command -v start > /dev/null; then
            start "$url" 2>/dev/null &
        else
            print_warning "Tidak dapat membuka browser otomatis"
            print_info "Silakan buka secara manual: $url"
        fi
    else
        print_error "Port tidak ditemukan untuk project $project_name"
        print_info "Coba jalankan './dev.sh restart' untuk setup ulang"
    fi
}

# Command: logs - Tampilkan real-time logs
cmd_logs() {
    local project_name=$(get_current_project)
    local log_type=$1
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    print_header
    print_info "Menampilkan logs untuk project: $project_name"
    
    case "$log_type" in
        "worker"|"queue")
            local log_file="$LOG_DIR/${project_name}-worker.log"
            ;;
        "scheduler"|"cron")
            local log_file="$LOG_DIR/${project_name}-scheduler.log"
            ;;
        "watcher"|"hot")
            local log_file="$LOG_DIR/${project_name}-watcher.log"
            ;;
        "error"|"laravel")
            local log_file="$PROJECTS_DIR/$project_name/storage/logs/laravel.log"
            ;;
        "access"|"web")
            local log_file="$LOG_DIR/dev_$(cat $PROJECTS_DIR/$project_name/.port 2>/dev/null || echo '8000').log"
            ;;
        "all"|"")
            # Show multiple logs
            print_info "Menampilkan semua logs (tekan Ctrl+C untuk keluar)..."
            echo -e "${YELLOW}Format: [LOG_TYPE] log_message${NC}\n"
            
            # Function to tail multiple logs
            tail_multiple_logs() {
                local worker_log="$LOG_DIR/${project_name}-worker.log"
                local scheduler_log="$LOG_DIR/${project_name}-scheduler.log"
                local laravel_log="$PROJECTS_DIR/$project_name/storage/logs/laravel.log"
                
                (
                    [ -f "$worker_log" ] && tail -f "$worker_log" | sed "s/^/[WORKER] /" &
                    [ -f "$scheduler_log" ] && tail -f "$scheduler_log" | sed "s/^/[SCHEDULER] /" &
                    [ -f "$laravel_log" ] && tail -f "$laravel_log" | sed "s/^/[LARAVEL] /" &
                    wait
                )
            }
            
            tail_multiple_logs
            return
            ;;
        *)
            print_error "Tipe log tidak dikenal: $log_type"
            echo -e "${YELLOW}Available log types:${NC}"
            echo -e "• ${GREEN}worker${NC} atau ${GREEN}queue${NC} - Queue worker logs"
            echo -e "• ${GREEN}scheduler${NC} atau ${GREEN}cron${NC} - Task scheduler logs"
            echo -e "• ${GREEN}watcher${NC} atau ${GREEN}hot${NC} - File watcher logs"
            echo -e "• ${GREEN}error${NC} atau ${GREEN}laravel${NC} - Laravel application logs"
            echo -e "• ${GREEN}access${NC} atau ${GREEN}web${NC} - Web server access logs"
            echo -e "• ${GREEN}all${NC} atau kosong - Semua logs"
            exit 1
            ;;
    esac
    
    if [ -f "$log_file" ]; then
        print_info "Mengikuti log: $log_file"
        print_info "Tekan Ctrl+C untuk keluar"
        echo -e "${CYAN}----------------------------------------${NC}"
        tail -f "$log_file"
    else
        print_warning "Log file tidak ditemukan: $log_file"
        print_info "Log mungkin belum ada atau service belum berjalan"
    fi
}

# Command: restart - Restart semua services
cmd_restart() {
    local project_name=$(get_current_project)
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    print_header
    print_info "Restarting development environment untuk project: $project_name"
    
    # Stop file watcher
    if [ -f "/tmp/${project_name}_watcher.pid" ]; then
        local watcher_pid=$(cat "/tmp/${project_name}_watcher.pid")
        kill "$watcher_pid" 2>/dev/null
        rm -f "/tmp/${project_name}_watcher.pid"
        print_success "File watcher dihentikan"
    fi
    
    # Restart supervisor processes
    print_info "Restarting supervisor processes..."
    supervisorctl restart "${project_name}:*"
    
    # Clear all caches
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    print_info "Clearing caches..."
    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
    php artisan cache:clear
    
    # Restart file watcher
    if command -v inotifywait > /dev/null; then
        print_info "Restarting file watcher..."
        nohup bash -c "
            while inotifywait -r -e modify,create,delete --exclude '(vendor|node_modules|\.git|storage/logs)' $project_path; do
                echo '[$(date)] File changed, clearing cache...' >> $LOG_DIR/${project_name}-watcher.log
                cd $project_path
                php artisan config:clear > /dev/null 2>&1
                php artisan route:clear > /dev/null 2>&1
                php artisan view:clear > /dev/null 2>&1
            done
        " > /dev/null 2>&1 &
        echo $! > "/tmp/${project_name}_watcher.pid"
    fi
    
    print_success "Development environment berhasil di-restart!"
    
    # Show status
    local port=""
    if [ -f "$project_path/.port" ]; then
        port=$(cat "$project_path/.port")
        echo -e "\n${GREEN}Ready at: http://localhost:$port${NC}"
    fi
}

# Command: stop - Stop development environment
cmd_stop() {
    local project_name=$(get_current_project)
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    print_header
    print_info "Stopping development environment untuk project: $project_name"
    
    # Stop file watcher
    if [ -f "/tmp/${project_name}_watcher.pid" ]; then
        local watcher_pid=$(cat "/tmp/${project_name}_watcher.pid")
        kill "$watcher_pid" 2>/dev/null
        rm -f "/tmp/${project_name}_watcher.pid"
        print_success "File watcher dihentikan"
    fi
    
    # Stop supervisor processes
    print_info "Stopping supervisor processes..."
    supervisorctl stop "${project_name}:*"
    
    print_success "Development environment untuk $project_name berhasil dihentikan"
}

# Command: status - Tampilkan status development environment
cmd_status() {
    local project_name=$(get_current_project)
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    print_header
    echo -e "${WHITE}Development Status: $project_name${NC}\n"
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    # Basic info
    echo -e "${CYAN}📁 Project:${NC} $project_name"
    echo -e "${CYAN}📂 Path:${NC} $project_path"
    
    # Port and URL
    if [ -f "$project_path/.port" ]; then
        local port=$(cat "$project_path/.port")
        echo -e "${CYAN}🌐 Port:${NC} $port"
        echo -e "${CYAN}🔗 URL:${NC} http://localhost:$port"
        
        # Health check
        if curl -f -s "http://localhost:$port" > /dev/null; then
            echo -e "${CYAN}💓 Health:${NC} ${GREEN}Healthy${NC}"
        else
            echo -e "${CYAN}💓 Health:${NC} ${RED}Not responding${NC}"
        fi
    fi
    
    # Supervisor processes
    echo -e "\n${CYAN}🔧 Supervisor Processes:${NC}"
    if supervisorctl status "${project_name}:*" 2>/dev/null | grep -q "$project_name"; then
        supervisorctl status "${project_name}:*" 2>/dev/null | while read line; do
            if [[ $line == *"RUNNING"* ]]; then
                echo -e "   ${GREEN}✓${NC} $line"
            elif [[ $line == *"STOPPED"* ]]; then
                echo -e "   ${YELLOW}⏸${NC} $line"
            else
                echo -e "   ${RED}✗${NC} $line"
            fi
        done
    else
        echo -e "   ${YELLOW}⚠${NC} No processes running"
    fi
    
    # File watcher status
    echo -e "\n${CYAN}👁 File Watcher:${NC}"
    if [ -f "/tmp/${project_name}_watcher.pid" ]; then
        local watcher_pid=$(cat "/tmp/${project_name}_watcher.pid")
        if kill -0 "$watcher_pid" 2>/dev/null; then
            echo -e "   ${GREEN}✓${NC} Running (PID: $watcher_pid)"
        else
            echo -e "   ${RED}✗${NC} Not running (stale PID file)"
            rm -f "/tmp/${project_name}_watcher.pid"
        fi
    else
        echo -e "   ${YELLOW}⏸${NC} Not running"
    fi
    
    # Dependencies status
    echo -e "\n${CYAN}📦 Dependencies:${NC}"
    cd "$project_path"
    
    # Composer
    if [ -d "vendor" ]; then
        if [ "composer.lock" -nt "vendor/autoload.php" ]; then
            echo -e "   ${YELLOW}⚠${NC} Composer: Needs update"
        else
            echo -e "   ${GREEN}✓${NC} Composer: Up to date"
        fi
    else
        echo -e "   ${RED}✗${NC} Composer: Not installed"
    fi
    
    # NPM
    if [ -f "package.json" ]; then
        if [ -d "node_modules" ]; then
            if [ "package.json" -nt "node_modules" ]; then
                echo -e "   ${YELLOW}⚠${NC} NPM: Needs update"
            else
                echo -e "   ${GREEN}✓${NC} NPM: Up to date"
            fi
        else
            echo -e "   ${RED}✗${NC} NPM: Not installed"
        fi
    else
        echo -e "   ${CYAN}ℹ${NC} NPM: No package.json"
    fi
    
    # Environment
    echo -e "\n${CYAN}⚙️ Environment:${NC}"
    if [ -f ".env" ]; then
        local app_env=$(grep "APP_ENV=" .env | cut -d'=' -f2)
        local app_debug=$(grep "APP_DEBUG=" .env | cut -d'=' -f2)
        echo -e "   ${GREEN}✓${NC} .env exists (ENV: $app_env, DEBUG: $app_debug)"
    else
        echo -e "   ${RED}✗${NC} .env file missing"
    fi
    
    # Recent activity
    echo -e "\n${CYAN}📊 Recent Activity:${NC}"
    local worker_log="$LOG_DIR/${project_name}-worker.log"
    if [ -f "$worker_log" ] && [ -s "$worker_log" ]; then
        echo -e "   ${GREEN}✓${NC} Worker activity: $(stat -c %y "$worker_log" | cut -d' ' -f1-2)"
    else
        echo -e "   ${YELLOW}⚠${NC} No recent worker activity"
    fi
}

# Command: build - Build assets untuk production
cmd_build() {
    local project_name=$(get_current_project)
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    print_header
    print_info "Building production assets untuk project: $project_name"
    
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    # Install production dependencies
    print_info "Installing production dependencies..."
    composer install --no-dev --optimize-autoloader --no-interaction
    
    # Build NPM assets
    if [ -f "package.json" ]; then
        print_info "Installing NPM dependencies..."
        npm ci --production
        
        # Check for build scripts
        if npm run --silent 2>/dev/null | grep -q "build"; then
            print_info "Building NPM assets..."
            npm run build
        elif npm run --silent 2>/dev/null | grep -q "production"; then
            print_info "Building NPM assets..."
            npm run production
        else
            print_warning "No build script found in package.json"
        fi
    fi
    
    # Optimize Laravel
    print_info "Optimizing Laravel..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan event:cache
    
    # Generate optimized autoloader
    composer dump-autoload --optimize --no-dev
    
    print_success "Production build berhasil!"
    print_info "Project siap untuk deployment"
}

# Command: fresh - Fresh start development
cmd_fresh() {
    local project_name=$(get_current_project)
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    print_header
    print_warning "Fresh start akan menghapus semua cache dan data development!"
    read -p "Apakah Anda yakin? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Fresh start dibatalkan"
        exit 0
    fi
    
    print_info "Fresh start untuk project: $project_name"
    
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    # Stop semua processes
    cmd_stop
    
    # Clear all caches
    print_info "Clearing all caches..."
    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
    php artisan cache:clear
    php artisan event:clear
    
    # Remove compiled files
    rm -rf bootstrap/cache/*.php
    rm -rf storage/framework/cache/data/*
    rm -rf storage/framework/sessions/*
    rm -rf storage/framework/views/*
    
    # Fresh database
    print_info "Fresh database migration..."
    php artisan migrate:fresh --seed --no-interaction
    
    # Reinstall dependencies
    print_info "Reinstalling dependencies..."
    rm -rf vendor node_modules
    composer install
    
    if [ -f "package.json" ]; then
        npm install
    fi
    
    # Generate new key
    php artisan key:generate --no-interaction
    
    # Start kembali
    cmd_start
    
    print_success "Fresh start berhasil!"
}

# Command: test - Jalankan tests
cmd_test() {
    local project_name=$(get_current_project)
    local test_type=$1
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    print_header
    print_info "Running tests untuk project: $project_name"
    
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    case "$test_type" in
        "unit")
            print_info "Running unit tests..."
            php artisan test --testsuite=Unit
            ;;
        "feature")
            print_info "Running feature tests..."
            php artisan test --testsuite=Feature
            ;;
        "coverage")
            print_info "Running tests with coverage..."
            php artisan test --coverage
            ;;
        "parallel")
            print_info "Running tests in parallel..."
            php artisan test --parallel
            ;;
        ""|"all")
            print_info "Running all tests..."
            php artisan test
            ;;
        *)
            print_info "Running specific test: $test_type"
            php artisan test --filter "$test_type"
            ;;
    esac
}

# Command: optimize - Optimize development environment
cmd_optimize() {
    local project_name=$(get_current_project)
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada current project yang aktif!"
        print_info "Gunakan './project.sh switch nama_project' untuk memilih project"
        exit 1
    fi
    
    check_project_exists "$project_name"
    
    print_header
    print_info "Optimizing development environment untuk project: $project_name"
    
    local project_path="$PROJECTS_DIR/$project_name"
    cd "$project_path"
    
    # Update dependencies
    print_info "Updating dependencies..."
    composer update --no-interaction
    
    if [ -f "package.json" ]; then
        npm update
    fi
    
    # Optimize autoloader
    print_info "Optimizing autoloader..."
    composer dump-autoload --optimize
    
    # Clear and cache
    print_info "Optimizing Laravel..."
    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
    php artisan cache:clear
    
    # Storage permissions
    print_info "Fixing permissions..."
    chmod -R 775 storage bootstrap/cache
    chown -R www-data:www-data storage bootstrap/cache
    
    print_success "Development environment berhasil dioptimasi!"
}

# Command: help - Tampilkan bantuan
cmd_help() {
    print_header
    echo -e "${WHITE}Available Commands:${NC}\n"
    
    echo -e "${CYAN}Development Workflow:${NC}"
    echo -e "  ${GREEN}start${NC}                - Start development environment"
    echo -e "  ${GREEN}stop${NC}                 - Stop development environment"
    echo -e "  ${GREEN}restart${NC}              - Restart all services"
    echo -e "  ${GREEN}status${NC}               - Tampilkan status development"
    
    echo -e "\n${CYAN}Browser & Monitoring:${NC}"
    echo -e "  ${GREEN}open${NC}                 - Buka project di browser"
    echo -e "  ${GREEN}logs [type]${NC}          - Tampilkan real-time logs"
    
    echo -e "\n${CYAN}Build & Deploy:${NC}"
    echo -e "  ${GREEN}build${NC}                - Build production assets"
    echo -e "  ${GREEN}fresh${NC}                - Fresh start development"
    echo -e "  ${GREEN}optimize${NC}             - Optimize development environment"
    
    echo -e "\n${CYAN}Testing:${NC}"
    echo -e "  ${GREEN}test [type]${NC}          - Jalankan tests"
    
    echo -e "\n${CYAN}Log Types:${NC}"
    echo -e "  ${GREEN}worker${NC} / ${GREEN}queue${NC}     - Queue worker logs"
    echo -e "  ${GREEN}scheduler${NC} / ${GREEN}cron${NC}   - Task scheduler logs" 
    echo -e "  ${GREEN}error${NC} / ${GREEN}laravel${NC}   - Application logs"
    echo -e "  ${GREEN}access${NC} / ${GREEN}web${NC}      - Web server logs"
    echo -e "  ${GREEN}all${NC}                 - Semua logs"
    
    echo -e "\n${CYAN}Test Types:${NC}"
    echo -e "  ${GREEN}unit${NC}                 - Unit tests only"
    echo -e "  ${GREEN}feature${NC}              - Feature tests only"
    echo -e "  ${GREEN}coverage${NC}             - Tests with coverage"
    echo -e "  ${GREEN}parallel${NC}             - Parallel test execution"
    echo -e "  ${GREEN}all${NC}                  - All tests"
    
    echo -e "\n${YELLOW}Tips:${NC}"
    echo -e "• Gunakan ${GREEN}./project.sh switch nama_project${NC} untuk memilih project aktif"
    echo -e "• File watcher otomatis clear cache saat file berubah"
    echo -e "• Logs bisa difilter berdasarkan tipe untuk debugging yang lebih mudah"
    echo -e "• Fresh command akan reset semua cache dan database"
    
    echo -e "\n${CYAN}Examples:${NC}"
    echo -e "  ./dev.sh start"
    echo -e "  ./dev.sh logs worker"
    echo -e "  ./dev.sh test unit"
    echo -e "  ./dev.sh build"
}

# Main script logic
main() {
    case "${1:-help}" in
        "start")
            cmd_start
            ;;
        "stop")
            cmd_stop
            ;;
        "restart")
            cmd_restart
            ;;
        "open")
            cmd_open
            ;;
        "logs")
            cmd_logs "$2"
            ;;
        "status")
            cmd_status
            ;;
        "build")
            cmd_build
            ;;
        "fresh")
            cmd_fresh
            ;;
        "test")
            cmd_test "$2"
            ;;
        "optimize")
            cmd_optimize
            ;;
        "help"|"-h"|"--help"|*)
            cmd_help
            ;;
    esac
}

# Jalankan script
main "$@"
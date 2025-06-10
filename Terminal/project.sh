#!/bin/bash

# ===============================================
# LaravelProjectContainer - Project Management Script
# ===============================================
# Script untuk mengelola multiple Laravel projects
# Penggunaan: ./project.sh [command] [arguments]
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
TERMINAL_DIR="/var/www/html/Terminal"
SUPERVISOR_PROJECTS_DIR="/etc/supervisor/conf.d/Projects"
CURRENT_PROJECT_FILE="/tmp/current_laravel_project"

# Helper functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${WHITE}  LaravelProjectContainer - Project Mgmt${NC}"
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

# Cek apakah folder projects exists
check_projects_dir() {
    if [ ! -d "$PROJECTS_DIR" ]; then
        print_error "Directory projects tidak ditemukan: $PROJECTS_DIR"
        print_info "Membuat directory projects..."
        mkdir -p "$PROJECTS_DIR"
        chown -R www-data:www-data "$PROJECTS_DIR"
        print_success "Directory projects berhasil dibuat"
    fi
}

# Cek apakah supervisor projects dir exists
check_supervisor_dir() {
    if [ ! -d "$SUPERVISOR_PROJECTS_DIR" ]; then
        print_info "Membuat directory supervisor projects..."
        mkdir -p "$SUPERVISOR_PROJECTS_DIR"
        print_success "Directory supervisor projects berhasil dibuat"
    fi
}

# Generate supervisor config untuk project
generate_supervisor_config() {
    local project_name=$1
    local config_file="$SUPERVISOR_PROJECTS_DIR/${project_name}.conf"
    
    cat > "$config_file" << EOF
# Supervisor configuration untuk project: $project_name
# Generated automatically oleh LaravelProjectContainer

[program:${project_name}-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/Projects/${project_name}/artisan queue:work --sleep=3 --tries=3 --max-time=3600
directory=/var/www/html/Projects/${project_name}
autostart=true
autorestart=true
startretries=3
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/laravel/${project_name}-worker.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
stopwaitsecs=3600
killasgroup=true
priority=999

[program:${project_name}-scheduler]
process_name=%(program_name)s
command=/bin/bash -c "while true; do php /var/www/html/Projects/${project_name}/artisan schedule:run --verbose --no-interaction; sleep 60; done"
directory=/var/www/html/Projects/${project_name}
autostart=true
autorestart=true
startretries=3
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/laravel/${project_name}-scheduler.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=3
stopwaitsecs=10
killasgroup=true
priority=997

[group:${project_name}]
programs=${project_name}-worker,${project_name}-scheduler
priority=999
EOF

    print_success "Supervisor config untuk $project_name berhasil dibuat"
}

# Setup Laravel project environment
setup_laravel_env() {
    local project_name=$1
    local project_path="$PROJECTS_DIR/$project_name"
    
    cd "$project_path"
    
    # Copy .env.example ke .env jika belum ada
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success ".env file berhasil dibuat dari .env.example"
        else
            # Create basic .env file
            cat > .env << EOF
APP_NAME=$project_name
APP_ENV=development
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=${project_name}
DB_USERNAME=laravel
DB_PASSWORD=laravel

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DRIVER=local
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@${project_name}.test"
MAIL_FROM_NAME="\${APP_NAME}"
EOF
            print_success "Basic .env file berhasil dibuat"
        fi
    fi
    
    # Generate application key
    php artisan key:generate --no-interaction
    print_success "Application key berhasil di-generate"
    
    # Set permissions
    chown -R www-data:www-data "$project_path"
    chmod -R 775 "$project_path/storage"
    chmod -R 775 "$project_path/bootstrap/cache"
    print_success "Permissions berhasil di-set"
}

# Create database untuk project
create_database() {
    local project_name=$1
    local db_name=${project_name}
    
    print_info "Membuat database: $db_name"
    
    # Create database via MySQL command
    mysql -h mysql -u laravel -p'laravel' -e "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Database $db_name berhasil dibuat"
    else
        print_warning "Database $db_name mungkin sudah ada atau gagal dibuat"
    fi
}

# Assign port untuk project
assign_port() {
    local project_name=$1
    local assigned_port=""
    
    # Check available ports 8000-8003
    for port in 8000 8001 8002 8003; do
        if [ ! -f "/tmp/port_${port}.lock" ]; then
            echo "$project_name" > "/tmp/port_${port}.lock"
            assigned_port=$port
            break
        fi
    done
    
    if [ -z "$assigned_port" ]; then
        print_warning "Semua development ports (8000-8003) sudah terpakai"
        print_info "Project akan menggunakan port 8000 (shared)"
        assigned_port=8000
    fi
    
    # Set environment variable untuk FrankenPHP
    export PROJECT_${assigned_port}=$project_name
    echo "export PROJECT_${assigned_port}=$project_name" >> /etc/environment
    
    print_success "Project $project_name assigned ke port $assigned_port"
    echo "$assigned_port" > "$PROJECTS_DIR/$project_name/.port"
}

# Command: new - Buat project Laravel baru
cmd_new() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        print_error "Nama project harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./project.sh new nama_project${NC}"
        exit 1
    fi
    
    # Validasi nama project
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Nama project hanya boleh mengandung huruf, angka, underscore, dan dash"
        exit 1
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ -d "$project_path" ]; then
        print_error "Project $project_name sudah ada!"
        exit 1
    fi
    
    print_header
    print_info "Membuat project Laravel baru: $project_name"
    
    check_projects_dir
    check_supervisor_dir
    
    # Create Laravel project
    print_info "Menginstall Laravel via Composer..."
    cd "$PROJECTS_DIR"
    composer create-project laravel/laravel "$project_name" --prefer-dist --no-interaction
    
    if [ $? -ne 0 ]; then
        print_error "Gagal membuat project Laravel"
        exit 1
    fi
    
    print_success "Project Laravel $project_name berhasil dibuat"
    
    # Setup environment
    setup_laravel_env "$project_name"
    
    # Create database
    create_database "$project_name"
    
    # Assign port
    assign_port "$project_name"
    
    # Generate supervisor config
    generate_supervisor_config "$project_name"
    
    # Reload supervisor
    supervisorctl reread
    supervisorctl update
    
    # Run initial migrations
    cd "$project_path"
    php artisan migrate --no-interaction
    print_success "Database migrations berhasil dijalankan"
    
    # Set sebagai current project
    echo "$project_name" > "$CURRENT_PROJECT_FILE"
    
    print_success "Project $project_name berhasil dibuat dan dikonfigurasi!"
    print_info "Port: $(cat $project_path/.port)"
    print_info "URL: http://localhost:$(cat $project_path/.port)"
    print_info "Database: $project_name"
    
    echo -e "\n${GREEN}Next steps:${NC}"
    echo -e "1. ${CYAN}./dev.sh start${NC} - Start development server"
    echo -e "2. ${CYAN}./dev.sh open${NC} - Buka project di browser"
    echo -e "3. ${CYAN}./project.sh switch $project_name${NC} - Switch ke project ini"
}

# Command: list - List semua project
cmd_list() {
    print_header
    print_info "Daftar Laravel Projects:"
    
    if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A $PROJECTS_DIR 2>/dev/null)" ]; then
        print_warning "Belum ada project yang dibuat"
        echo -e "${YELLOW}Gunakan: ./project.sh new nama_project untuk membuat project baru${NC}"
        return
    fi
    
    local current_project=""
    if [ -f "$CURRENT_PROJECT_FILE" ]; then
        current_project=$(cat "$CURRENT_PROJECT_FILE")
    fi
    
    echo -e "\n${CYAN}No.  Project Name          Port    Status    Current${NC}"
    echo -e "${CYAN}---  ------------------    ----    -------   -------${NC}"
    
    local counter=1
    for project_dir in "$PROJECTS_DIR"/*; do
        if [ -d "$project_dir" ]; then
            local project_name=$(basename "$project_dir")
            local port="N/A"
            local status="Unknown"
            local is_current=""
            
            # Get port
            if [ -f "$project_dir/.port" ]; then
                port=$(cat "$project_dir/.port")
            fi
            
            # Check status
            if [ -f "$project_dir/artisan" ]; then
                status="Ready"
            else
                status="Incomplete"
            fi
            
            # Check if current
            if [ "$project_name" = "$current_project" ]; then
                is_current="⭐"
            fi
            
            printf "%-3s  %-18s    %-4s    %-7s   %s\n" "$counter" "$project_name" "$port" "$status" "$is_current"
            counter=$((counter + 1))
        fi
    done
    
    if [ -n "$current_project" ]; then
        echo -e "\n${GREEN}Current active project: $current_project${NC}"
    fi
}

# Command: switch - Switch ke project tertentu
cmd_switch() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        print_error "Nama project harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./project.sh switch nama_project${NC}"
        exit 1
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project $project_name tidak ditemukan!"
        print_info "Gunakan './project.sh list' untuk melihat daftar project"
        exit 1
    fi
    
    echo "$project_name" > "$CURRENT_PROJECT_FILE"
    print_success "Switched ke project: $project_name"
    
    if [ -f "$project_path/.port" ]; then
        local port=$(cat "$project_path/.port")
        print_info "Port: $port"
        print_info "URL: http://localhost:$port"
    fi
}

# Command: open - Buka project di browser
cmd_open() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        if [ -f "$CURRENT_PROJECT_FILE" ]; then
            project_name=$(cat "$CURRENT_PROJECT_FILE")
        else
            print_error "Tidak ada current project dan nama project tidak diisi!"
            echo -e "${YELLOW}Penggunaan: ./project.sh open [nama_project]${NC}"
            exit 1
        fi
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project $project_name tidak ditemukan!"
        exit 1
    fi
    
    if [ -f "$project_path/.port" ]; then
        local port=$(cat "$project_path/.port")
        local url="http://localhost:$port"
        
        print_info "Membuka $project_name di browser..."
        print_info "URL: $url"
        
        # Try to open browser (works in most environments)
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
    fi
}

# Command: delete - Hapus project
cmd_delete() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        print_error "Nama project harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./project.sh delete nama_project${NC}"
        exit 1
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project $project_name tidak ditemukan!"
        exit 1
    fi
    
    print_warning "PERINGATAN: Ini akan menghapus project $project_name secara permanen!"
    print_warning "Termasuk database, files, dan konfigurasi supervisor"
    
    read -p "Apakah Anda yakin? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Penghapusan dibatalkan"
        exit 0
    fi
    
    # Stop supervisor processes
    if [ -f "$SUPERVISOR_PROJECTS_DIR/${project_name}.conf" ]; then
        supervisorctl stop "${project_name}:*" 2>/dev/null
        rm -f "$SUPERVISOR_PROJECTS_DIR/${project_name}.conf"
        supervisorctl reread
        supervisorctl update
        print_success "Supervisor processes untuk $project_name dihentikan"
    fi
    
    # Release port
    if [ -f "$project_path/.port" ]; then
        local port=$(cat "$project_path/.port")
        rm -f "/tmp/port_${port}.lock"
        print_success "Port $port berhasil di-release"
    fi
    
    # Drop database
    mysql -h mysql -u laravel -p'laravel' -e "DROP DATABASE IF EXISTS \`$project_name\`;" 2>/dev/null
    print_success "Database $project_name berhasil dihapus"
    
    # Remove project directory
    rm -rf "$project_path"
    print_success "Directory project $project_name berhasil dihapus"
    
    # Remove from current project if it's active
    if [ -f "$CURRENT_PROJECT_FILE" ]; then
        local current_project=$(cat "$CURRENT_PROJECT_FILE")
        if [ "$current_project" = "$project_name" ]; then
            rm -f "$CURRENT_PROJECT_FILE"
            print_info "Current project reference dihapus"
        fi
    fi
    
    print_success "Project $project_name berhasil dihapus sepenuhnya!"
}

# Command: status - Tampilkan status project
cmd_status() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        if [ -f "$CURRENT_PROJECT_FILE" ]; then
            project_name=$(cat "$CURRENT_PROJECT_FILE")
        else
            print_error "Tidak ada current project dan nama project tidak diisi!"
            echo -e "${YELLOW}Penggunaan: ./project.sh status [nama_project]${NC}"
            exit 1
        fi
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project $project_name tidak ditemukan!"
        exit 1
    fi
    
    print_header
    echo -e "${WHITE}Status Project: $project_name${NC}\n"
    
    # Basic info
    echo -e "${CYAN}📁 Path:${NC} $project_path"
    
    if [ -f "$project_path/.port" ]; then
        local port=$(cat "$project_path/.port")
        echo -e "${CYAN}🌐 Port:${NC} $port"
        echo -e "${CYAN}🔗 URL:${NC} http://localhost:$port"
    fi
    
    # Laravel version
    if [ -f "$project_path/artisan" ]; then
        cd "$project_path"
        local laravel_version=$(php artisan --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        echo -e "${CYAN}🚀 Laravel:${NC} $laravel_version"
    fi
    
    # Database status
    if [ -f "$project_path/.env" ]; then
        local db_name=$(grep "DB_DATABASE=" "$project_path/.env" | cut -d'=' -f2)
        local db_check=$(mysql -h mysql -u laravel -p'laravel' -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$db_name';" 2>/dev/null | grep "$db_name")
        if [ -n "$db_check" ]; then
            echo -e "${CYAN}🗄️  Database:${NC} $db_name ${GREEN}(Connected)${NC}"
        else
            echo -e "${CYAN}🗄️  Database:${NC} $db_name ${RED}(Not Found)${NC}"
        fi
    fi
    
    # Supervisor processes
    echo -e "\n${CYAN}📊 Supervisor Processes:${NC}"
    if supervisorctl status "${project_name}:*" 2>/dev/null | grep -q "$project_name"; then
        supervisorctl status "${project_name}:*" 2>/dev/null | while read line; do
            if [[ $line == *"RUNNING"* ]]; then
                echo -e "   ${GREEN}✓${NC} $line"
            else
                echo -e "   ${RED}✗${NC} $line"
            fi
        done
    else
        echo -e "   ${YELLOW}⚠${NC} No supervisor processes configured"
    fi
    
    # Recent logs
    echo -e "\n${CYAN}📋 Recent Logs:${NC}"
    local log_file="/var/log/laravel/${project_name}-worker.log"
    if [ -f "$log_file" ]; then
        echo -e "${YELLOW}Last 3 lines from worker log:${NC}"
        tail -n 3 "$log_file" | sed 's/^/   /'
    else
        echo -e "   ${YELLOW}⚠${NC} No worker logs found"
    fi
}

# Command: clone - Clone project dari Git repository
cmd_clone() {
    local repo_url=$1
    local project_name=$2
    
    if [ -z "$repo_url" ]; then
        print_error "URL repository harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./project.sh clone <git_url> [nama_project]${NC}"
        exit 1
    fi
    
    # Extract project name from URL if not provided
    if [ -z "$project_name" ]; then
        project_name=$(basename "$repo_url" .git)
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ -d "$project_path" ]; then
        print_error "Project $project_name sudah ada!"
        exit 1
    fi
    
    print_header
    print_info "Cloning project dari repository: $repo_url"
    
    check_projects_dir
    check_supervisor_dir
    
    # Clone repository
    cd "$PROJECTS_DIR"
    git clone "$repo_url" "$project_name"
    
    if [ $? -ne 0 ]; then
        print_error "Gagal clone repository"
        exit 1
    fi
    
    print_success "Repository berhasil di-clone"
    
    # Check if it's a Laravel project
    if [ ! -f "$project_path/artisan" ]; then
        print_error "Repository ini bukan project Laravel yang valid"
        rm -rf "$project_path"
        exit 1
    fi
    
    cd "$project_path"
    
    # Install dependencies
    print_info "Installing Composer dependencies..."
    composer install --no-dev --optimize-autoloader
    
    if [ -f "package.json" ]; then
        print_info "Installing NPM dependencies..."
        npm install --production
    fi
    
    # Setup environment
    setup_laravel_env "$project_name"
    
    # Create database
    create_database "$project_name"
    
    # Assign port
    assign_port "$project_name"
    
    # Generate supervisor config
    generate_supervisor_config "$project_name"
    
    # Reload supervisor
    supervisorctl reread
    supervisorctl update
    
    # Run migrations
    php artisan migrate --no-interaction
    print_success "Database migrations berhasil dijalankan"
    
    # Set sebagai current project
    echo "$project_name" > "$CURRENT_PROJECT_FILE"
    
    print_success "Project $project_name berhasil di-clone dan dikonfigurasi!"
    print_info "Port: $(cat $project_path/.port)"
    print_info "URL: http://localhost:$(cat $project_path/.port)"
}

# Command: backup - Backup project
cmd_backup() {
    local project_name=$1
    
    if [ -z "$project_name" ]; then
        if [ -f "$CURRENT_PROJECT_FILE" ]; then
            project_name=$(cat "$CURRENT_PROJECT_FILE")
        else
            print_error "Tidak ada current project dan nama project tidak diisi!"
            echo -e "${YELLOW}Penggunaan: ./project.sh backup [nama_project]${NC}"
            exit 1
        fi
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ ! -d "$project_path" ]; then
        print_error "Project $project_name tidak ditemukan!"
        exit 1
    fi
    
    local backup_dir="/var/www/html/backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${backup_dir}/${project_name}_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    print_header
    print_info "Membuat backup untuk project: $project_name"
    
    # Backup database
    print_info "Backup database..."
    mysqldump -h mysql -u laravel -p'laravel' "$project_name" > "/tmp/${project_name}_${timestamp}.sql"
    
    # Create project backup
    print_info "Backup project files..."
    cd "$PROJECTS_DIR"
    tar -czf "$backup_file" \
        --exclude="$project_name/node_modules" \
        --exclude="$project_name/vendor" \
        --exclude="$project_name/.git" \
        --exclude="$project_name/storage/logs/*" \
        "$project_name"
    
    # Add database backup to archive
    tar -rzf "$backup_file" -C /tmp "${project_name}_${timestamp}.sql"
    
    # Cleanup temp database file
    rm -f "/tmp/${project_name}_${timestamp}.sql"
    
    print_success "Backup berhasil dibuat: $backup_file"
    print_info "Size: $(du -h $backup_file | cut -f1)"
}

# Command: restore - Restore project dari backup
cmd_restore() {
    local backup_file=$1
    local project_name=$2
    
    if [ -z "$backup_file" ]; then
        print_error "File backup harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./project.sh restore <backup_file> [nama_project]${NC}"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "File backup tidak ditemukan: $backup_file"
        exit 1
    fi
    
    # Extract project name from backup if not provided
    if [ -z "$project_name" ]; then
        project_name=$(basename "$backup_file" | sed 's/_[0-9]\{8\}_[0-9]\{6\}\.tar\.gz$//')
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    
    if [ -d "$project_path" ]; then
        print_warning "Project $project_name sudah ada!"
        read -p "Apakah Anda ingin menimpa? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_info "Restore dibatalkan"
            exit 0
        fi
        rm -rf "$project_path"
    fi
    
    print_header
    print_info "Restore project dari backup: $backup_file"
    
    check_projects_dir
    
    # Extract backup
    cd "$PROJECTS_DIR"
    tar -xzf "$backup_file"
    
    if [ $? -ne 0 ]; then
        print_error "Gagal extract backup"
        exit 1
    fi
    
    print_success "Project files berhasil di-restore"
    
    # Restore database
    local sql_file=$(find /tmp -name "${project_name}_*.sql" | head -n 1)
    if [ -f "$sql_file" ]; then
        print_info "Restore database..."
        create_database "$project_name"
        mysql -h mysql -u laravel -p'laravel' "$project_name" < "$sql_file"
        rm -f "$sql_file"
        print_success "Database berhasil di-restore"
    fi
    
    # Reinstall dependencies
    cd "$project_path"
    composer install
    
    if [ -f "package.json" ]; then
        npm install
    fi
    
    # Setup environment
    setup_laravel_env "$project_name"
    
    # Assign port
    assign_port "$project_name"
    
    # Generate supervisor config
    generate_supervisor_config "$project_name"
    
    # Reload supervisor
    supervisorctl reread
    supervisorctl update
    
    print_success "Project $project_name berhasil di-restore!"
}

# Command: help - Tampilkan bantuan
cmd_help() {
    print_header
    echo -e "${WHITE}Available Commands:${NC}\n"
    
    echo -e "${CYAN}Project Management:${NC}"
    echo -e "  ${GREEN}new <nama>${NC}           - Buat project Laravel baru"
    echo -e "  ${GREEN}clone <url> [nama]${NC}   - Clone project dari Git repository"
    echo -e "  ${GREEN}list${NC}                 - Tampilkan daftar semua project"
    echo -e "  ${GREEN}switch <nama>${NC}        - Switch ke project tertentu"
    echo -e "  ${GREEN}delete <nama>${NC}        - Hapus project (PERMANENT!)"
    echo -e "  ${GREEN}status [nama]${NC}        - Tampilkan status project"
    
    echo -e "\n${CYAN}Browser & Access:${NC}"
    echo -e "  ${GREEN}open [nama]${NC}          - Buka project di browser"
    
    echo -e "\n${CYAN}Backup & Restore:${NC}"
    echo -e "  ${GREEN}backup [nama]${NC}        - Backup project dan database"
    echo -e "  ${GREEN}restore <file> [nama]${NC} - Restore project dari backup"
    
    echo -e "\n${CYAN}Information:${NC}"
    echo -e "  ${GREEN}help${NC}                 - Tampilkan bantuan ini"
    
    echo -e "\n${YELLOW}Tips:${NC}"
    echo -e "• Jika nama project tidak diisi, akan menggunakan current active project"
    echo -e "• Gunakan ${GREEN}./dev.sh${NC} untuk development workflow"
    echo -e "• Gunakan ${GREEN}./artisan.sh${NC} untuk Laravel Artisan commands"
    echo -e "• Gunakan ${GREEN}./database.sh${NC} untuk database management"
    
    echo -e "\n${CYAN}Examples:${NC}"
    echo -e "  ./project.sh new myapp"
    echo -e "  ./project.sh clone https://github.com/user/repo.git"
    echo -e "  ./project.sh switch myapp"
    echo -e "  ./project.sh open myapp"
    echo -e "  ./project.sh backup myapp"
}

# Main script logic
main() {
    case "${1:-help}" in
        "new")
            cmd_new "$2"
            ;;
        "list")
            cmd_list
            ;;
        "switch")
            cmd_switch "$2"
            ;;
        "open")
            cmd_open "$2"
            ;;
        "delete")
            cmd_delete "$2"
            ;;
        "status")
            cmd_status "$2"
            ;;
        "clone")
            cmd_clone "$2" "$3"
            ;;
        "backup")
            cmd_backup "$2"
            ;;
        "restore")
            cmd_restore "$2" "$3"
            ;;
        "help"|"-h"|"--help"|*)
            cmd_help
            ;;
    esac
}

# Jalankan script
main "$@"
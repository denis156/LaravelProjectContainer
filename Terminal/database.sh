#!/bin/bash

# ===============================================
# LaravelProjectContainer - Database Management Script
# ===============================================
# Script untuk mengelola database operations
# Penggunaan: ./database.sh [command] [arguments]
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
BACKUP_DIR="/var/www/html/backups/database"

# Database credentials
DB_HOST="mysql"
DB_ROOT_USER="root"
DB_ROOT_PASSWORD="laravel_root"
DB_USER="laravel"
DB_PASSWORD="laravel"

# Helper functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${WHITE}  LaravelProjectContainer - Database${NC}"
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

# Get project database name
get_project_db() {
    local project_name=$1
    if [ -z "$project_name" ]; then
        project_name=$(get_current_project)
    fi
    
    if [ -z "$project_name" ]; then
        print_error "Tidak ada project yang aktif!"
        return 1
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    if [ -f "$project_path/.env" ]; then
        grep "DB_DATABASE=" "$project_path/.env" | cut -d'=' -f2 | tr -d '"' | tr -d "'"
    else
        echo "$project_name"
    fi
}

# Check database connection
check_db_connection() {
    if ! mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1; then
        print_error "Tidak dapat connect ke database!"
        print_info "Pastikan MySQL container berjalan"
        return 1
    fi
    return 0
}

# Create backup directory
ensure_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    chown -R www-data:www-data "$BACKUP_DIR"
}

# Command: backup - Backup database
cmd_backup() {
    local project_name=${1:-$(get_current_project)}
    local custom_name=$2
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh backup [project_name] [custom_name]${NC}"
        exit 1
    fi
    
    check_db_connection || exit 1
    ensure_backup_dir
    
    local db_name=$(get_project_db "$project_name")
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="${custom_name:-${project_name}_${timestamp}}"
    local backup_file="$BACKUP_DIR/${backup_name}.sql"
    
    print_info "Backing up database: $db_name"
    print_info "Backup file: $backup_file"
    
    mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --add-drop-database \
        --databases "$db_name" > "$backup_file"
    
    if [ $? -eq 0 ]; then
        # Compress backup
        gzip "$backup_file"
        local compressed_file="${backup_file}.gz"
        
        print_success "Database backup berhasil!"
        print_info "File: $compressed_file"
        print_info "Size: $(du -h "$compressed_file" | cut -f1)"
    else
        print_error "Backup gagal!"
        rm -f "$backup_file"
        exit 1
    fi
}

# Command: restore - Restore database
cmd_restore() {
    local project_name=${1:-$(get_current_project)}
    local backup_file=$2
    
    if [ -z "$project_name" ] || [ -z "$backup_file" ]; then
        print_error "Project name dan backup file harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh restore <project_name> <backup_file>${NC}"
        exit 1
    fi
    
    # Check if backup file exists
    if [ ! -f "$backup_file" ] && [ ! -f "$BACKUP_DIR/$backup_file" ]; then
        # Try with .gz extension
        if [ -f "$BACKUP_DIR/${backup_file}.gz" ]; then
            backup_file="$BACKUP_DIR/${backup_file}.gz"
        elif [ -f "$BACKUP_DIR/${backup_file}.sql.gz" ]; then
            backup_file="$BACKUP_DIR/${backup_file}.sql.gz"
        else
            print_error "Backup file tidak ditemukan: $backup_file"
            print_info "Available backups:"
            ls -la "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "No backups found"
            exit 1
        fi
    elif [ -f "$BACKUP_DIR/$backup_file" ]; then
        backup_file="$BACKUP_DIR/$backup_file"
    fi
    
    check_db_connection || exit 1
    
    local db_name=$(get_project_db "$project_name")
    
    print_warning "Ini akan menimpa database: $db_name"
    read -p "Apakah Anda yakin? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Restore dibatalkan"
        exit 0
    fi
    
    print_info "Restoring database: $db_name"
    print_info "From file: $backup_file"
    
    # Drop and recreate database
    mysql -h "$DB_HOST" -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`$db_name\`;"
    mysql -h "$DB_HOST" -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" -e "CREATE DATABASE \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    # Restore from backup
    if [[ "$backup_file" == *.gz ]]; then
        zcat "$backup_file" | mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$db_name"
    else
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$db_name" < "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Database berhasil di-restore!"
        
        # Update project if it exists
        local project_path="$PROJECTS_DIR/$project_name"
        if [ -d "$project_path" ]; then
            cd "$project_path"
            if [ -f "artisan" ]; then
                print_info "Running post-restore commands..."
                php artisan config:clear
                php artisan cache:clear
                print_success "Post-restore cleanup completed"
            fi
        fi
    else
        print_error "Restore gagal!"
        exit 1
    fi
}

# Command: migrate - Run migrations for project
cmd_migrate() {
    local project_name=${1:-$(get_current_project)}
    local action=${2:-"run"}
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh migrate [project_name] [action]${NC}"
        exit 1
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    if [ ! -d "$project_path" ]; then
        print_error "Project tidak ditemukan: $project_name"
        exit 1
    fi
    
    cd "$project_path"
    
    case "$action" in
        "run"|"")
            print_info "Running migrations untuk $project_name..."
            php artisan migrate --no-interaction
            ;;
        "fresh")
            print_warning "Fresh migrate akan menghapus semua data!"
            read -p "Apakah Anda yakin? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                php artisan migrate:fresh --seed --no-interaction
            else
                print_info "Fresh migrate dibatalkan"
            fi
            ;;
        "rollback")
            local steps=${3:-1}
            print_info "Rolling back $steps migration(s)..."
            php artisan migrate:rollback --step="$steps" --no-interaction
            ;;
        "status")
            print_info "Migration status untuk $project_name:"
            php artisan migrate:status
            ;;
        *)
            print_error "Migration action tidak dikenal: $action"
            echo -e "${YELLOW}Available actions: run, fresh, rollback, status${NC}"
            ;;
    esac
}

# Command: fresh - Fresh migration with seeding
cmd_fresh() {
    local project_name=${1:-$(get_current_project)}
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh fresh [project_name]${NC}"
        exit 1
    fi
    
    print_warning "Fresh migration akan menghapus SEMUA data di database!"
    read -p "Apakah Anda yakin? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Fresh migration dibatalkan"
        exit 0
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    if [ ! -d "$project_path" ]; then
        print_error "Project tidak ditemukan: $project_name"
        exit 1
    fi
    
    cd "$project_path"
    
    print_info "Running fresh migration dengan seeding untuk $project_name..."
    php artisan migrate:fresh --seed --no-interaction
    
    if [ $? -eq 0 ]; then
        print_success "Fresh migration berhasil!"
    else
        print_error "Fresh migration gagal!"
        exit 1
    fi
}

# Command: seed - Run database seeders
cmd_seed() {
    local project_name=${1:-$(get_current_project)}
    local seeder_class=$2
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh seed [project_name] [seeder_class]${NC}"
        exit 1
    fi
    
    local project_path="$PROJECTS_DIR/$project_name"
    if [ ! -d "$project_path" ]; then
        print_error "Project tidak ditemukan: $project_name"
        exit 1
    fi
    
    cd "$project_path"
    
    if [ -z "$seeder_class" ]; then
        print_info "Running all seeders untuk $project_name..."
        php artisan db:seed --no-interaction
    else
        print_info "Running seeder: $seeder_class untuk $project_name..."
        php artisan db:seed --class="$seeder_class" --no-interaction
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Seeding berhasil!"
    else
        print_error "Seeding gagal!"
        exit 1
    fi
}

# Command: list - List all databases
cmd_list() {
    check_db_connection || exit 1
    
    print_info "Daftar databases:"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;" | grep -v -E "(Database|information_schema|performance_schema|mysql|sys)"
}

# Command: size - Show database sizes
cmd_size() {
    check_db_connection || exit 1
    
    print_info "Database sizes:"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "
    SELECT 
        table_schema AS 'Database',
        ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
    FROM information_schema.tables 
    WHERE table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
    GROUP BY table_schema
    ORDER BY SUM(data_length + index_length) DESC;"
}

# Command: tables - Show tables for project database
cmd_tables() {
    local project_name=${1:-$(get_current_project)}
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        exit 1
    fi
    
    check_db_connection || exit 1
    
    local db_name=$(get_project_db "$project_name")
    print_info "Tables in database: $db_name"
    
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "USE \`$db_name\`; SHOW TABLES;"
}

# Command: export - Export database to SQL
cmd_export() {
    local project_name=${1:-$(get_current_project)}
    local output_file=$2
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh export [project_name] [output_file]${NC}"
        exit 1
    fi
    
    check_db_connection || exit 1
    
    local db_name=$(get_project_db "$project_name")
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local export_file="${output_file:-${project_name}_export_${timestamp}.sql}"
    
    # Ensure absolute path
    if [[ "$export_file" != /* ]]; then
        export_file="$PWD/$export_file"
    fi
    
    print_info "Exporting database: $db_name"
    print_info "Export file: $export_file"
    
    mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --no-create-db \
        "$db_name" > "$export_file"
    
    if [ $? -eq 0 ]; then
        print_success "Database exported successfully!"
        print_info "File: $export_file"
        print_info "Size: $(du -h "$export_file" | cut -f1)"
    else
        print_error "Export gagal!"
        rm -f "$export_file"
        exit 1
    fi
}

# Command: import - Import SQL file to database
cmd_import() {
    local project_name=${1:-$(get_current_project)}
    local sql_file=$2
    
    if [ -z "$project_name" ] || [ -z "$sql_file" ]; then
        print_error "Project name dan SQL file harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh import <project_name> <sql_file>${NC}"
        exit 1
    fi
    
    if [ ! -f "$sql_file" ]; then
        print_error "SQL file tidak ditemukan: $sql_file"
        exit 1
    fi
    
    check_db_connection || exit 1
    
    local db_name=$(get_project_db "$project_name")
    
    print_warning "Ini akan mengimport data ke database: $db_name"
    read -p "Apakah Anda yakin? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Import dibatalkan"
        exit 0
    fi
    
    print_info "Importing to database: $db_name"
    print_info "From file: $sql_file"
    
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$db_name" < "$sql_file"
    
    if [ $? -eq 0 ]; then
        print_success "Import berhasil!"
    else
        print_error "Import gagal!"
        exit 1
    fi
}

# Command: drop - Drop database
cmd_drop() {
    local project_name=${1:-$(get_current_project)}
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh drop <project_name>${NC}"
        exit 1
    fi
    
    check_db_connection || exit 1
    
    local db_name=$(get_project_db "$project_name")
    
    print_warning "PERINGATAN: Ini akan menghapus database '$db_name' secara PERMANEN!"
    print_warning "Semua data akan hilang dan tidak dapat dikembalikan!"
    read -p "Ketik nama database untuk konfirmasi: " confirm_db
    
    if [ "$confirm_db" != "$db_name" ]; then
        print_error "Nama database tidak cocok. Drop dibatalkan."
        exit 1
    fi
    
    read -p "Apakah Anda benar-benar yakin? (YES/no): " final_confirm
    if [ "$final_confirm" != "YES" ]; then
        print_info "Drop database dibatalkan"
        exit 0
    fi
    
    print_info "Dropping database: $db_name"
    mysql -h "$DB_HOST" -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`$db_name\`;"
    
    if [ $? -eq 0 ]; then
        print_success "Database $db_name berhasil dihapus!"
    else
        print_error "Drop database gagal!"
        exit 1
    fi
}

# Command: create - Create new database
cmd_create() {
    local db_name=$1
    
    if [ -z "$db_name" ]; then
        print_error "Database name harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh create <database_name>${NC}"
        exit 1
    fi
    
    check_db_connection || exit 1
    
    print_info "Creating database: $db_name"
    mysql -h "$DB_HOST" -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    if [ $? -eq 0 ]; then
        print_success "Database $db_name berhasil dibuat!"
    else
        print_error "Create database gagal!"
        exit 1
    fi
}

# Command: clone - Clone database
cmd_clone() {
    local source_project=${1:-$(get_current_project)}
    local target_db=$2
    
    if [ -z "$source_project" ] || [ -z "$target_db" ]; then
        print_error "Source project dan target database harus diisi!"
        echo -e "${YELLOW}Penggunaan: ./database.sh clone <source_project> <target_database>${NC}"
        exit 1
    fi
    
    check_db_connection || exit 1
    
    local source_db=$(get_project_db "$source_project")
    
    print_info "Cloning database: $source_db -> $target_db"
    
    # Create target database
    mysql -h "$DB_HOST" -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$target_db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    # Clone data
    mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" --single-transaction --routines --triggers "$source_db" | mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$target_db"
    
    if [ $? -eq 0 ]; then
        print_success "Database berhasil di-clone!"
        print_info "Source: $source_db"
        print_info "Target: $target_db"
    else
        print_error "Clone database gagal!"
        exit 1
    fi
}

# Command: backups - List available backups
cmd_backups() {
    ensure_backup_dir
    
    print_info "Available database backups:"
    if ls "$BACKUP_DIR"/*.sql.gz 1> /dev/null 2>&1; then
        ls -lah "$BACKUP_DIR"/*.sql.gz | awk '{print $5, $6, $7, $8, $9}' | column -t
    else
        print_warning "No backups found in $BACKUP_DIR"
    fi
}

# Command: optimize - Optimize database tables
cmd_optimize() {
    local project_name=${1:-$(get_current_project)}
    
    if [ -z "$project_name" ]; then
        print_error "Project name harus diisi!"
        exit 1
    fi
    
    check_db_connection || exit 1
    
    local db_name=$(get_project_db "$project_name")
    print_info "Optimizing database: $db_name"
    
    # Get all tables
    local tables=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -Bse "USE \`$db_name\`; SHOW TABLES;")
    
    for table in $tables; do
        print_info "Optimizing table: $table"
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "USE \`$db_name\`; OPTIMIZE TABLE \`$table\`;" > /dev/null
    done
    
    print_success "Database optimization completed!"
}

# Command: help - Tampilkan bantuan
cmd_help() {
    print_header
    echo -e "${WHITE}Database Management Commands${NC}\n"
    
    echo -e "${CYAN}Backup & Restore:${NC}"
    echo -e "  ${GREEN}backup [project] [name]${NC}    - Backup database"
    echo -e "  ${GREEN}restore <project> <file>${NC}   - Restore from backup"
    echo -e "  ${GREEN}backups${NC}                    - List available backups"
    
    echo -e "\n${CYAN}Migration & Seeding:${NC}"
    echo -e "  ${GREEN}migrate [project] [action]${NC}  - Run migrations"
    echo -e "  ${GREEN}fresh [project]${NC}             - Fresh migrate + seed"
    echo -e "  ${GREEN}seed [project] [seeder]${NC}     - Run database seeders"
    
    echo -e "\n${CYAN}Import & Export:${NC}"
    echo -e "  ${GREEN}export [project] [file]${NC}     - Export to SQL file"
    echo -e "  ${GREEN}import <project> <file>${NC}     - Import from SQL file"
    
    echo -e "\n${CYAN}Database Operations:${NC}"
    echo -e "  ${GREEN}create <name>${NC}               - Create new database"
    echo -e "  ${GREEN}drop <project>${NC}              - Drop database (DANGER!)"
    echo -e "  ${GREEN}clone <source> <target>${NC}     - Clone database"
    
    echo -e "\n${CYAN}Information:${NC}"
    echo -e "  ${GREEN}list${NC}                        - List all databases"
    echo -e "  ${GREEN}size${NC}                        - Show database sizes"
    echo -e "  ${GREEN}tables [project]${NC}            - Show tables in database"
    echo -e "  ${GREEN}optimize [project]${NC}          - Optimize database tables"
    
    echo -e "\n${CYAN}Migration Actions:${NC}"
    echo -e "  ${GREEN}run${NC} - Run pending migrations (default)"
    echo -e "  ${GREEN}fresh${NC} - Fresh migrate with seeding"
    echo -e "  ${GREEN}rollback${NC} - Rollback migrations"
    echo -e "  ${GREEN}status${NC} - Show migration status"
    
    echo -e "\n${YELLOW}Tips:${NC}"
    echo -e "• Backups disimpan di $BACKUP_DIR"
    echo -e "• Backups otomatis di-compress dengan gzip"
    echo -e "• Gunakan current active project jika tidak disebutkan"
    echo -e "• Drop database memerlukan konfirmasi ganda"
    
    echo -e "\n${CYAN}Examples:${NC}"
    echo -e "  ./database.sh backup myapp"
    echo -e "  ./database.sh restore myapp myapp_20231201_120000.sql.gz"
    echo -e "  ./database.sh migrate myapp fresh"
    echo -e "  ./database.sh clone myapp myapp_staging"
}

# Main script logic
main() {
    case "${1:-help}" in
        "backup"|"bak")
            shift
            cmd_backup "$@"
            ;;
        "restore"|"res")
            shift
            cmd_restore "$@"
            ;;
        "migrate"|"mig")
            shift
            cmd_migrate "$@"
            ;;
        "fresh")
            shift
            cmd_fresh "$@"
            ;;
        "seed")
            shift
            cmd_seed "$@"
            ;;
        "list"|"ls")
            cmd_list
            ;;
        "size")
            cmd_size
            ;;
        "tables"|"tbl")
            shift
            cmd_tables "$@"
            ;;
        "export"|"exp")
            shift
            cmd_export "$@"
            ;;
        "import"|"imp")
            shift
            cmd_import "$@"
            ;;
        "drop")
            shift
            cmd_drop "$@"
            ;;
        "create")
            shift
            cmd_create "$@"
            ;;
        "clone")
            shift
            cmd_clone "$@"
            ;;
        "backups")
            cmd_backups
            ;;
        "optimize"|"opt")
            shift
            cmd_optimize "$@"
            ;;
        "help"|"-h"|"--help"|*)
            cmd_help
            ;;
    esac
}

# Jalankan script
main "$@"
# 🖥️ Terminal Scripts Documentation

<div align="center">

<img src="../Image/Logo-ArteliaDev-rounded.png" width="200" alt="Artelia.Dev Logo">

[![Terminal](https://img.shields.io/badge/Terminal-Magic-brightgreen?style=for-the-badge&logo=gnubash)](https://github.com/denis156/LaravelProjectContainer)
[![Scripts](https://img.shields.io/badge/Scripts-6-blue?style=for-the-badge&logo=script)](https://github.com/denis156/LaravelProjectContainer)
[![Automation](https://img.shields.io/badge/Automation-100%25-orange?style=for-the-badge&logo=automation)](https://github.com/denis156/LaravelProjectContainer)
[![Artelia.Dev](https://img.shields.io/badge/Artelia.Dev-Leader-red?style=for-the-badge&logo=dev.to)](https://artelia.dev)

**Created by [Denis Djodian Ardika](https://github.com/denis156) - Artelia.Dev**

</div>

> **🎪 Terminal Commands yang Bikin Development Jadi Fun!** - Semua operasi dalam satu tempat yang user-friendly!

## 🚀 Overview

Terminal scripts adalah jantung dari LaravelProjectContainer! Dengan 6 script powerful ini, kamu bisa:
- 🏗️ Manage multiple Laravel projects
- ⚡ Automate development workflow  
- 🗄️ Handle database operations
- 🌐 Manage domains & SSL
- 🚀 Deploy to production
- 🎯 Run Laravel commands

## 📦 Available Scripts

| Script | Purpose | Commands |
|--------|---------|----------|
| 🏗️ `project.sh` | Project Management | `new`, `list`, `switch`, `delete`, `clone`, `backup` |
| ⚡ `dev.sh` | Development Workflow | `start`, `stop`, `restart`, `open`, `logs`, `status` |
| 🎯 `artisan.sh` | Laravel Artisan | `migrate`, `make`, `serve`, `tinker`, `queue`, `cache` |
| 📦 `composer.sh` | Package Management | `install`, `require`, `update`, `remove`, `audit` |
| 🗄️ `database.sh` | Database Operations | `backup`, `restore`, `migrate`, `fresh`, `seed`, `clone` |
| 🌐 `domain.sh` | Domain & SSL | `add`, `remove`, `ssl`, `list`, `test` |
| 🚀 `deploy.sh` | Production Deploy | `deploy`, `rollback`, `status`, `logs`, `cleanup` |

## 🏗️ Project Management (`project.sh`)

> **"Kelola semua Laravel projects dalam satu container!"**

### 🆕 Create New Project
```bash
# Create new Laravel project dengan auto-setup!
./Terminal/project.sh new awesome-app

# Clone dari Git repository
./Terminal/project.sh clone https://github.com/username/repo.git
./Terminal/project.sh clone https://github.com/username/repo.git custom-name
```

### 📋 List & Switch Projects
```bash
# List semua projects dengan status
./Terminal/project.sh list

# Switch ke project lain
./Terminal/project.sh switch awesome-app

# Open project di browser
./Terminal/project.sh open awesome-app
```

### 🗂️ Project Information
```bash
# Show detailed project status
./Terminal/project.sh status awesome-app

# Backup project (files + database)
./Terminal/project.sh backup awesome-app
./Terminal/project.sh backup awesome-app custom-backup-name

# Restore project dari backup
./Terminal/project.sh restore backup-file.tar.gz
./Terminal/project.sh restore backup-file.tar.gz custom-project-name
```

### ⚠️ Delete Project
```bash
# Delete project (dengan konfirmasi safety!)
./Terminal/project.sh delete awesome-app
# → Akan hapus: files, database, supervisor config, port release
```

**✨ Auto Features:**
- 🎯 Auto port assignment (8000-8003)
- 🗄️ Auto database creation  
- ⚙️ Auto supervisor configuration
- 🔧 Auto .env setup
- 📦 Auto dependencies installation

---

## ⚡ Development Workflow (`dev.sh`)

> **"Development workflow yang smooth seperti mentega!"**

### 🚀 Start Development
```bash
# Start development environment untuk current project
./Terminal/dev.sh start
# → Install dependencies, run migrations, start file watcher

# Open project di browser (auto-detect port)
./Terminal/dev.sh open
```

### 📊 Monitor Development
```bash
# Show development status
./Terminal/dev.sh status

# View logs dengan filtering
./Terminal/dev.sh logs               # Semua logs
./Terminal/dev.sh logs worker        # Queue worker logs
./Terminal/dev.sh logs error         # Laravel error logs
./Terminal/dev.sh logs access        # Web server logs
```

### 🔄 Control Services
```bash
# Restart semua services
./Terminal/dev.sh restart

# Stop development environment
./Terminal/dev.sh stop
```

### 🛠️ Advanced Operations
```bash
# Build production assets
./Terminal/dev.sh build

# Fresh start (reset cache, database, dependencies)
./Terminal/dev.sh fresh

# Run tests
./Terminal/dev.sh test               # All tests
./Terminal/dev.sh test unit          # Unit tests only
./Terminal/dev.sh test feature       # Feature tests only

# Optimize development environment
./Terminal/dev.sh optimize
```

**✨ Auto Features:**
- 🔥 Hot reload dengan file watcher
- 📦 Auto dependency updates
- 🗄️ Auto migration checks
- 🎯 Smart cache clearing
- 💓 Health monitoring

---

## 🎯 Laravel Artisan (`artisan.sh`)

> **"Semua Laravel commands dalam satu tempat yang mudah!"**

### 🗄️ Database Operations
```bash
# Migrations
./Terminal/artisan.sh migrate               # Run migrations
./Terminal/artisan.sh migrate fresh         # Fresh migration + seed
./Terminal/artisan.sh migrate rollback      # Rollback 1 step
./Terminal/artisan.sh migrate rollback 3    # Rollback 3 steps  
./Terminal/artisan.sh migrate status        # Migration status

# Seeding
./Terminal/artisan.sh seed                  # Run all seeders
./Terminal/artisan.sh seed UserSeeder       # Run specific seeder
```

### 🏗️ Code Generation
```bash
# Models
./Terminal/artisan.sh make model User
./Terminal/artisan.sh make model Post -mcr  # Model + Migration + Controller + Resource

# Controllers
./Terminal/artisan.sh make controller UserController
./Terminal/artisan.sh make controller PostController --resource

# Other generators
./Terminal/artisan.sh make migration create_posts_table
./Terminal/artisan.sh make seeder UserSeeder
./Terminal/artisan.sh make factory PostFactory
./Terminal/artisan.sh make middleware AuthMiddleware
./Terminal/artisan.sh make request UserRequest
./Terminal/artisan.sh make mail WelcomeMail
./Terminal/artisan.sh make job ProcessPayment
```

### 🚀 Queue Management
```bash
# Queue workers
./Terminal/artisan.sh queue work            # Start worker
./Terminal/artisan.sh queue listen          # Start listener
./Terminal/artisan.sh queue restart         # Restart workers

# Failed jobs
./Terminal/artisan.sh queue failed          # List failed jobs
./Terminal/artisan.sh queue retry all       # Retry all failed
./Terminal/artisan.sh queue retry 5         # Retry specific job
./Terminal/artisan.sh queue flush           # Delete all failed
```

### 🎪 Cache Management
```bash
# Clear caches
./Terminal/artisan.sh cache clear           # App cache
./Terminal/artisan.sh cache config          # Config cache
./Terminal/artisan.sh cache route           # Route cache
./Terminal/artisan.sh cache view            # View cache
./Terminal/artisan.sh cache all             # Clear semua

# Optimize for production
./Terminal/artisan.sh cache optimize        # Cache semua untuk production
```

### 🛠️ Development Tools
```bash
# Development server
./Terminal/artisan.sh serve                 # Start pada 0.0.0.0:8000
./Terminal/artisan.sh serve 127.0.0.1 8080  # Custom host/port

# Interactive tools
./Terminal/artisan.sh tinker                # Laravel REPL

# Routes
./Terminal/artisan.sh route list            # List all routes
./Terminal/artisan.sh route cache           # Cache routes

# Scheduler
./Terminal/artisan.sh schedule run          # Run scheduled tasks
./Terminal/artisan.sh schedule list         # List scheduled tasks

# Maintenance
./Terminal/artisan.sh down "Maintenance"    # Enable maintenance mode
./Terminal/artisan.sh up                    # Disable maintenance mode
```

**✨ Smart Features:**
- 🎯 Auto-detects current project
- 📝 Interactive help untuk setiap command
- ⚠️ Safety confirmations untuk destructive operations
- 🎨 Colored output untuk better readability

---

## 📦 Composer Management (`composer.sh`)

> **"Package management yang cerdas dengan auto-publish!"**

### 📥 Install Dependencies
```bash
# Install modes
./Terminal/composer.sh install              # Development mode
./Terminal/composer.sh install prod         # Production only
./Terminal/composer.sh install fast         # Fast install + optimize
./Terminal/composer.sh install fresh        # Fresh install (hapus vendor)
```

### 📦 Package Management
```bash
# Add packages
./Terminal/composer.sh require laravel/telescope
./Terminal/composer.sh require phpunit/phpunit --dev
./Terminal/composer.sh require guzzlehttp/guzzle ^7.0

# Remove packages  
./Terminal/composer.sh remove laravel/telescope

# Update packages
./Terminal/composer.sh update               # Update all
./Terminal/composer.sh update security      # Security updates only
./Terminal/composer.sh update laravel/framework  # Specific package
```

### 🔍 Information & Analysis
```bash
# Package information
./Terminal/composer.sh show                 # List all packages
./Terminal/composer.sh show laravel/framework  # Specific package info
./Terminal/composer.sh search telescope     # Search packages

# Security & maintenance
./Terminal/composer.sh audit                # Security audit
./Terminal/composer.sh outdated             # Check outdated packages
./Terminal/composer.sh licenses             # Show licenses
./Terminal/composer.sh why doctrine/orm     # Why package installed
```

### 🛠️ Maintenance Operations
```bash
# Autoloader
./Terminal/composer.sh dumpautoload         # Normal autoloader
./Terminal/composer.sh dumpautoload optimize  # Optimized autoloader
./Terminal/composer.sh dumpautoload classmap  # Authoritative classmap

# Scripts & diagnostics
./Terminal/composer.sh scripts              # List available scripts
./Terminal/composer.sh run test             # Run composer script
./Terminal/composer.sh diagnose             # Diagnose problems
./Terminal/composer.sh validate             # Validate composer.json
```

**✨ Auto Features:**
- 🎯 Auto-publish config untuk Laravel packages populer (Telescope, Horizon, Sanctum, dll)
- 🔒 Safety confirmations untuk destructive operations
- 📊 Smart package suggestions
- 🎨 Colored output dengan status indicators

**🎪 Laravel Package Auto-Publish:**
```bash
# Otomatis di-publish saat install:
laravel/telescope    → php artisan telescope:install
laravel/horizon      → php artisan horizon:install  
laravel/sanctum      → php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
laravel/passport     → php artisan passport:install
spatie/laravel-permission → php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
```

---

## 🗄️ Database Operations (`database.sh`)

> **"Database management yang powerful dengan safety first!"**

### 💾 Backup & Restore
```bash
# Backup database
./Terminal/database.sh backup myapp                    # Auto timestamp
./Terminal/database.sh backup myapp custom-backup      # Custom name

# Restore database
./Terminal/database.sh restore myapp backup-file.sql.gz
./Terminal/database.sh restore myapp myapp_20231201_120000.sql.gz

# List available backups
./Terminal/database.sh backups
```

### 🔄 Migration Operations
```bash
# Run migrations per-project
./Terminal/database.sh migrate myapp              # Run pending
./Terminal/database.sh migrate myapp fresh        # Fresh + seed
./Terminal/database.sh migrate myapp rollback     # Rollback 1 step
./Terminal/database.sh migrate myapp status       # Check status

# Fresh migration dengan seeding
./Terminal/database.sh fresh myapp
```

### 🌱 Seeding Operations
```bash
# Run seeders
./Terminal/database.sh seed myapp                 # All seeders
./Terminal/database.sh seed myapp UserSeeder      # Specific seeder
```

### 📊 Database Information
```bash
# List databases
./Terminal/database.sh list

# Show database sizes
./Terminal/database.sh size

# Show tables dalam project database
./Terminal/database.sh tables myapp
```

### 📥📤 Import/Export
```bash
# Export to SQL file
./Terminal/database.sh export myapp
./Terminal/database.sh export myapp custom-export.sql

# Import from SQL file
./Terminal/database.sh import myapp data.sql
```

### 🏗️ Database Management
```bash
# Create new database
./Terminal/database.sh create new_database

# Clone database
./Terminal/database.sh clone myapp myapp_staging

# Drop database (DANGER! Double confirmation required)
./Terminal/database.sh drop myapp

# Optimize database tables
./Terminal/database.sh optimize myapp
```

**✨ Safety Features:**
- 🔒 Double confirmation untuk destructive operations
- 💾 Auto-compressed backups dengan gzip
- 🎯 Auto database creation untuk new projects
- 📅 Timestamp-based backup naming
- 🔄 Transaction-safe operations

**📁 Backup Storage:**
- Location: `/var/www/html/backups/database/`
- Format: `{project}_{timestamp}.sql.gz`
- Auto-compression untuk space efficiency

---

## 🌐 Domain & SSL Management (`domain.sh`)

> **"Kelola domains dan SSL certificates dengan mudah!"**

### 🌍 Domain Operations
```bash
# Add domains
./Terminal/domain.sh add myapp.test myapp dev         # Development domain
./Terminal/domain.sh add staging.myapp.com myapp staging  # Staging domain  
./Terminal/domain.sh add myapp.com myapp production   # Production domain

# List all domains
./Terminal/domain.sh list

# Remove domain
./Terminal/domain.sh remove myapp.test

# Switch project domain
./Terminal/domain.sh switch myapp newdomain.com
```

### 🔐 SSL Management
```bash
# SSL operations
./Terminal/domain.sh ssl status                    # Check all SSL status
./Terminal/domain.sh ssl status myapp.com          # Check specific domain
./Terminal/domain.sh ssl enable myapp.com          # Enable SSL
./Terminal/domain.sh ssl disable myapp.test        # Disable SSL
./Terminal/domain.sh ssl renew                     # Force renewal
```

### 🧪 Testing & Monitoring
```bash
# Test domain configuration
./Terminal/domain.sh test myapp.com                # HTTP/HTTPS connectivity
./Terminal/domain.sh test localhost                # Local testing

# View domain logs
./Terminal/domain.sh logs myapp.com                # Access logs
./Terminal/domain.sh logs myapp.com 100            # Last 100 lines
```

### 💾 Backup & Restore
```bash
# Backup domain configuration
./Terminal/domain.sh backup                        # Auto timestamp
./Terminal/domain.sh backup my-domains.conf        # Custom name

# Restore domain configuration
./Terminal/domain.sh restore my-domains.conf
```

**🎯 Auto-Detection Rules:**
```bash
# SSL Auto-Detection:
localhost/*     → SSL disabled, type=dev
*.test         → SSL disabled, type=dev  
staging.*      → SSL enabled, type=staging
*.staging.*    → SSL enabled, type=staging
other domains  → SSL enabled, type=production
```

**🌐 Domain Types:**
- **dev**: No SSL, CORS enabled, relaxed security
- **staging**: SSL enabled, moderate security, debugging tools
- **production**: SSL + full security headers, rate limiting, optimizations

---

## 🚀 Production Deployment (`deploy.sh`)

> **"Deploy ke production dengan confidence dan safety!"**

### 🚀 Main Deployment
```bash
# Deploy to environments
./Terminal/deploy.sh deploy myapp staging           # Deploy to staging
./Terminal/deploy.sh deploy myapp production        # Deploy to production  
./Terminal/deploy.sh deploy myapp production true   # Force migrations

# Deployment process:
# 1. Pre-deployment checks
# 2. Create backup
# 3. Build assets  
# 4. Optimize Laravel
# 5. Run migrations
# 6. Restart services
# 7. Health checks
# 8. Save deployment info
```

### ↩️ Rollback Operations
```bash
# Rollback deployment
./Terminal/deploy.sh rollback myapp production      # Rollback latest
./Terminal/deploy.sh rollback myapp staging
```

### 📊 Monitoring & Status
```bash
# Check deployment status
./Terminal/deploy.sh status myapp                   # All environments
./Terminal/deploy.sh status myapp production        # Specific environment

# View deployment logs
./Terminal/deploy.sh logs myapp staging             # Last 50 lines
./Terminal/deploy.sh logs myapp production 100      # Last 100 lines

# Deployment history
./Terminal/deploy.sh history myapp                  # All environments
./Terminal/deploy.sh history myapp production       # Specific environment
```

### 🧹 Maintenance
```bash
# Cleanup old deployments (keep latest 5)
./Terminal/deploy.sh cleanup myapp                  # Keep 5 (default)
./Terminal/deploy.sh cleanup myapp 3                # Keep 3

# Show deployment configuration
./Terminal/deploy.sh config show myapp
```

**✨ Deployment Features:**
- 🔒 Production safety checks (clean git status required)
- 💾 Auto-backup sebelum deployment
- 🎯 Health checks post-deployment
- ⚡ Zero-downtime deployment
- 📊 Deployment tracking & history
- ↩️ One-command rollback
- 🚨 Smart error handling

**🎪 Deployment Environments:**
- **development**: Local development, full debugging
- **staging**: Pre-production testing, moderate optimization
- **production**: Full optimization, security, monitoring

---

## 🎨 Terminal Features

### 🌈 Colored Output
Semua scripts menggunakan colored output untuk better UX:
- 🔵 **Blue**: Headers dan titles
- 🟢 **Green**: Success messages  
- 🟡 **Yellow**: Warnings
- 🔴 **Red**: Errors
- 🟣 **Purple**: Process steps
- 🟦 **Cyan**: Information

### 🛡️ Safety Features
- ⚠️ **Interactive confirmations** untuk destructive operations
- 🔒 **Double confirmation** untuk production operations
- 💾 **Auto-backups** sebelum major changes
- 🎯 **Validation** untuk inputs dan prerequisites
- 📝 **Clear error messages** dengan suggestions

### 🔄 Smart Defaults
- 🎯 Auto-detect current project jika tidak disebutkan
- 📁 Auto-create directories yang dibutuhkan
- ⚙️ Auto-setup configurations
- 🔧 Auto-install dependencies
- 📊 Auto-health checks

## 💡 Pro Tips & Tricks

### 🔥 **Quick Commands**
```bash
# Chain commands untuk workflow cepat
./Terminal/project.sh switch myapp && ./Terminal/dev.sh start && ./Terminal/dev.sh open

# Quick fresh start
./Terminal/dev.sh fresh  # Reset everything!

# Monitor real-time
./Terminal/dev.sh logs all  # All logs combined

# Quick deployment check
./Terminal/deploy.sh status myapp production && ./Terminal/domain.sh test myapp.com
```

### 🎯 **Aliases untuk Speed**
Buat aliases di bashrc/zshrc:
```bash
alias lpc-new='./Terminal/project.sh new'
alias lpc-start='./Terminal/dev.sh start'  
alias lpc-deploy='./Terminal/deploy.sh deploy'
alias lpc-logs='./Terminal/dev.sh logs'
```

### 🚀 **Production Checklist**
```bash
# Pre-deployment checklist:
1. ./Terminal/project.sh status myapp          # Check project health
2. ./Terminal/database.sh backup myapp         # Manual backup  
3. ./Terminal/deploy.sh config show myapp      # Review config
4. ./Terminal/deploy.sh deploy myapp production # Deploy!
5. ./Terminal/domain.sh test myapp.com         # Test domain
6. ./Terminal/deploy.sh status myapp production # Verify deployment
```

### 🎪 **Development Workflow**
```bash
# Daily development workflow:
1. ./Terminal/project.sh switch current-project
2. ./Terminal/dev.sh start                     # Start environment
3. ./Terminal/dev.sh logs error               # Monitor errors
4. ./Terminal/artisan.sh migrate              # Run migrations
5. ./Terminal/composer.sh require new-package # Add packages
6. ./Terminal/dev.sh test                     # Run tests
7. ./Terminal/database.sh backup current-project # Backup before major changes
```

## 🐛 Troubleshooting

### 🔧 **Common Issues**

**Port already in use:**
```bash
# Check port usage
./Terminal/project.sh list
./Terminal/dev.sh status

# Restart container
docker-compose restart frankenphp
```

**Database connection failed:**
```bash
# Check database status
./Terminal/database.sh list
docker-compose ps mysql

# Restart MySQL
docker-compose restart mysql
```

**File permissions:**
```bash
# Fix permissions dalam container
docker exec -it laravel_frankenphp bash
chown -R www-data:www-data /var/www/html/projects
chmod -R 755 /var/www/html/Terminal
```

**SSL certificate issues:**
```bash
# Force SSL renewal
./Terminal/domain.sh ssl renew

# Check SSL status
./Terminal/domain.sh ssl status myapp.com

# Restart FrankenPHP
docker-compose restart frankenphp
```

### 📞 **Getting Help**
```bash
# Setiap script punya help command:
./Terminal/project.sh help
./Terminal/dev.sh help  
./Terminal/artisan.sh help
./Terminal/composer.sh help
./Terminal/database.sh help
./Terminal/domain.sh help
./Terminal/deploy.sh help
```

---

<div align="center">

**🎉 Selamat Development dengan LaravelProjectContainer! 🎉**

**Made with ❤️ by [Denis Djodian Ardika](https://github.com/denis156)**

**Leader & Founder of [Artelia.Dev](https://artelia.dev)**

[![GitHub](https://img.shields.io/badge/Follow-denis156-black?style=social&logo=github)](https://github.com/denis156)
[![Artelia.Dev](https://img.shields.io/badge/Visit-Artelia.Dev-orange?style=social&logo=dev.to)](https://artelia.dev)

*"Life is too short for boring development setups!"*

</div># 🖥️ Terminal Scripts Documentation

[![Terminal](https://img.shields.io/badge/Terminal-Magic-brightgreen?style=for-the-badge&logo=gnubash)](https://github.com)
[![Scripts](https://img.shields.io/badge/Scripts-6-blue?style=for-the-badge&logo=script)](https://github.com)
[![Automation](https://img.
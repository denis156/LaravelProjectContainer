# 📁 Projects Documentation

<div align="center">

<img src="../Image/Logo-ArteliaDev-rounded.png" width="200" alt="Artelia.Dev Logo">

[![Projects](https://img.shields.io/badge/Multi--Project-Support-brightgreen?style=for-the-badge&logo=laravel)](https://github.com/denis156/LaravelProjectContainer)
[![Laravel](https://img.shields.io/badge/Laravel-Ready-red?style=for-the-badge&logo=laravel)](https://laravel.com)
[![Hot Reload](https://img.shields.io/badge/Hot--Reload-Enabled-orange?style=for-the-badge&logo=webpack)](https://github.com/denis156/LaravelProjectContainer)
[![Artelia.Dev](https://img.shields.io/badge/Artelia.Dev-Denis%20Djodian%20Ardika-blue?style=for-the-badge&logo=dev.to)](https://artelia.dev)

**Created by [Denis Djodian Ardika](https://github.com/denis156) - Artelia.Dev**

</div>

> **🎪 Multi-Project Management yang Bikin Happy!** - Kelola unlimited Laravel projects dalam satu container dengan mudah!

## 🌟 Overview

Folder `Projects/` adalah jantung dari LaravelProjectContainer! Di sinilah semua Laravel projects kamu tinggal dengan harmonis. Dengan sistem yang cerdas, setiap project mendapat:

- 🎯 **Port terpisah** untuk development (8000-8003)
- 🗄️ **Database terpisah** dengan auto-setup
- ⚙️ **Supervisor config** untuk background processes
- 🔥 **Hot reload** dengan file watching
- 🌐 **Custom domain** support

## 📦 Folder Structure

```
Projects/
├── awesome-app/                 # Laravel Project #1
│   ├── app/
│   ├── bootstrap/
│   ├── config/
│   ├── database/
│   ├── public/
│   ├── resources/
│   ├── routes/
│   ├── storage/
│   ├── tests/
│   ├── vendor/
│   ├── .env                     # Environment file
│   ├── .port                    # Auto-assigned port (8000)
│   ├── artisan                  # Laravel CLI
│   ├── composer.json
│   └── package.json
├── api-backend/                 # Laravel Project #2
│   ├── app/
│   ├── public/
│   ├── .env
│   ├── .port                    # Auto-assigned port (8001)
│   └── ...
├── admin-panel/                 # Laravel Project #3  
│   ├── app/
│   ├── public/
│   ├── .env
│   ├── .port                    # Auto-assigned port (8002)
│   └── ...
└── client-portal/               # Laravel Project #4
    ├── app/
    ├── public/
    ├── .env
    ├── .port                    # Auto-assigned port (8003)
    └── ...
```

## 🚀 How It Works

### 🎯 **Auto-Detection System**

Container secara otomatis mendeteksi semua Laravel projects:

```bash
# Check projects yang terdeteksi
./Terminal/project.sh list

# Output:
# No.  Project Name          Port    Status    Current
# ---  ------------------    ----    -------   -------  
# 1    awesome-app           8000    Ready     ⭐
# 2    api-backend           8001    Ready     
# 3    admin-panel           8002    Ready     
# 4    client-portal         8003    Ready     
```

### 🌐 **Port Assignment Magic**

Setiap project mendapat port development terpisah:

| Port | Usage | URL | Description |
|------|-------|-----|-------------|
| `8000` | Main Project | `http://localhost:8000` | Project pertama / default |
| `8001` | Second Project | `http://localhost:8001` | Project kedua |
| `8002` | Third Project | `http://localhost:8002` | Project ketiga |
| `8003` | Fourth Project | `http://localhost:8003` | Project keempat |

### 🗄️ **Database Per-Project**

Setiap project mendapat database terpisah:

```sql
-- Auto-created databases:
awesome_app     -- untuk project awesome-app
api_backend     -- untuk project api-backend  
admin_panel     -- untuk project admin-panel
client_portal   -- untuk project client-portal
```

## 🏗️ Project Creation Process

### 🆕 **Create New Project**

```bash
# Create project baru dengan full auto-setup!
./Terminal/project.sh new my-awesome-app
```

**🎪 What happens behind the scenes:**

1. **📦 Laravel Installation**
   ```bash
   composer create-project laravel/laravel my-awesome-app --prefer-dist
   ```

2. **🎯 Port Assignment**
   - Scan ports 8000-8003 untuk slot kosong
   - Assign port dan simpan ke `.port` file
   - Update environment variables

3. **🗄️ Database Setup**
   ```bash
   # Create database
   mysql> CREATE DATABASE my_awesome_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   
   # Update .env file
   DB_DATABASE=my_awesome_app
   DB_HOST=mysql
   DB_USERNAME=laravel
   DB_PASSWORD=laravel
   ```

4. **⚙️ Environment Configuration**
   ```bash
   # Auto-generate .env dengan container settings
   APP_NAME=my-awesome-app
   APP_URL=http://localhost:8000
   
   # Database settings
   DB_CONNECTION=mysql
   DB_HOST=mysql
   DB_PORT=3306
   
   # Cache & Session (Redis)
   CACHE_DRIVER=redis
   SESSION_DRIVER=redis
   QUEUE_CONNECTION=redis
   REDIS_HOST=redis
   
   # Mail (MailHog for testing)
   MAIL_MAILER=smtp
   MAIL_HOST=mailhog
   MAIL_PORT=1025
   ```

5. **🔧 Laravel Setup**
   ```bash
   php artisan key:generate
   php artisan migrate
   chmod -R 775 storage bootstrap/cache
   chown -R www-data:www-data .
   ```

6. **⚙️ Supervisor Configuration**
   - Generate worker config untuk queue processing
   - Setup scheduler untuk cron jobs
   - Auto-start background processes

### 📥 **Clone from Git**

```bash
# Clone existing Laravel project
./Terminal/project.sh clone https://github.com/username/laravel-app.git
./Terminal/project.sh clone https://github.com/username/laravel-app.git custom-name
```

**🎪 Clone process:**

1. **📦 Git Clone**
   ```bash
   git clone <repository-url> <project-name>
   ```

2. **✅ Laravel Validation**
   - Check untuk `artisan` file
   - Validate project structure

3. **📦 Dependencies**
   ```bash
   composer install --optimize-autoloader
   npm install  # jika ada package.json
   ```

4. **🔧 Auto-Setup**
   - Same setup process seperti new project
   - Environment configuration
   - Database creation
   - Migration running

## 🔄 Project Switching

### 🔄 **Active Project Concept**

LaravelProjectContainer menggunakan konsep "active project":

```bash
# Set active project
./Terminal/project.sh switch awesome-app

# Stored di: /tmp/current_laravel_project
# Semua Terminal commands akan otomatis target project ini
```

### 🎯 **Command Targeting**

Semua Terminal commands otomatis target active project:

```bash
# Switch ke project  
./Terminal/project.sh switch api-backend

# Commands berikut akan target 'api-backend':
./Terminal/dev.sh start           # Start api-backend
./Terminal/artisan.sh migrate     # Migrate api-backend  
./Terminal/database.sh backup     # Backup api-backend
./Terminal/composer.sh install    # Install deps for api-backend
```

## 🔥 Hot Reload System

### 👁️ **File Watching**

Setiap project mendapat file watcher untuk auto-reload:

```bash
# File watcher monitors:
- app/          # PHP files
- config/       # Configuration changes
- routes/       # Route definitions  
- resources/    # Views, CSS, JS
- database/     # Migrations, seeders

# Excluded from watching:
- vendor/       # Composer dependencies
- node_modules/ # NPM dependencies
- .git/         # Git files
- storage/logs/ # Log files
```

### ⚡ **Auto-Clear Cache**

Saat file berubah, system otomatis:

```bash
# Cache clearing sequence:
php artisan config:clear    # Clear config cache
php artisan route:clear     # Clear route cache  
php artisan view:clear      # Clear view cache

# Background process restart:
supervisorctl restart project-name:worker
```

### 📊 **File Watcher Logs**

Monitor file watcher activity:

```bash
# View file watcher logs
./Terminal/dev.sh logs watcher

# Output example:
# [2024-01-01 10:30:15] File changed: app/Models/User.php
# [2024-01-01 10:30:15] Clearing config cache...
# [2024-01-01 10:30:16] Cache cleared successfully
```

## 🌐 Domain Management

### 🏠 **Development Domains**

Default development URLs:

```bash
# Localhost development
http://localhost:8000    # awesome-app
http://localhost:8001    # api-backend  
http://localhost:8002    # admin-panel
http://localhost:8003    # client-portal
```

### 🎯 **Custom Domains**

Add custom domains untuk better development experience:

```bash
# Development domains (.test)
./Terminal/domain.sh add awesome-app.test awesome-app dev
./Terminal/domain.sh add api.test api-backend dev

# Staging domains  
./Terminal/domain.sh add staging.awesome-app.com awesome-app staging

# Production domains
./Terminal/domain.sh add awesome-app.com awesome-app production
```

### 🔐 **SSL Support**

Automatic SSL untuk production domains:

```bash
# Production dengan auto-SSL
./Terminal/domain.sh add myapp.com myapp production
# → SSL certificate otomatis di-generate oleh Let's Encrypt!

# Check SSL status
./Terminal/domain.sh ssl status myapp.com
```

## 📊 Project Monitoring

### 💓 **Health Monitoring**

System monitoring untuk setiap project:

```bash
# Project health check
./Terminal/project.sh status awesome-app

# Output:
# Status Project: awesome-app
# 📁 Path: /var/www/html/projects/awesome-app  
# 🌐 Port: 8000
# 🔗 URL: http://localhost:8000
# 💓 Health: Healthy
# 🚀 Laravel: 11.0.0
# 🗄️ Database: awesome_app (Connected)
```

### 📈 **Development Status**

Monitor development environment:

```bash
# Development status
./Terminal/dev.sh status

# Output:
# Development Status: awesome-app
# 📁 Project: awesome-app
# 🌐 Port: 8000  
# 💓 Health: Healthy
# 🔧 Supervisor Processes: ✓ Running
# 👁 File Watcher: ✓ Running (PID: 1234)
# 📦 Dependencies: ✓ Up to date
# ⚙️ Environment: .env exists (ENV: development, DEBUG: true)
```

### 📊 **Resource Usage**

Monitor resource usage per project:

```bash
# Database sizes
./Terminal/database.sh size

# Output:
# Database sizes:
# Database        Size (MB)
# awesome_app     45.67
# api_backend     23.12
# admin_panel     67.89
```

## 🛠️ Environment Management

### ⚙️ **Per-Project Configuration**

Setiap project punya environment terpisah:

```bash
# Project-specific .env files:
Projects/awesome-app/.env     # awesome-app config
Projects/api-backend/.env     # api-backend config  
Projects/admin-panel/.env     # admin-panel config
```

### 🎯 **Auto-Generated Settings**

Container otomatis generate optimal settings:

```bash
# Database connection
DB_CONNECTION=mysql
DB_HOST=mysql                 # Container MySQL service
DB_PORT=3306
DB_DATABASE={project_name}    # Auto-generated database name
DB_USERNAME=laravel           # Container database user
DB_PASSWORD=laravel

# Cache & Session  
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
REDIS_HOST=redis              # Container Redis service

# Mail Testing
MAIL_MAILER=smtp
MAIL_HOST=mailhog             # Container MailHog service
MAIL_PORT=1025

# Application URL
APP_URL=http://localhost:{auto_assigned_port}
```

### 🔧 **Custom Configuration**

Override default settings untuk specific needs:

```bash
# Edit project .env
nano Projects/awesome-app/.env

# Custom database
DB_DATABASE=custom_awesome_db

# External Redis  
REDIS_HOST=external-redis.com
REDIS_PASSWORD=secret

# Production mail
MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_USERNAME=your_username
MAIL_PASSWORD=your_password
```

## 🚀 Production Deployment

### 📦 **Build Process**

Prepare project untuk production:

```bash
# Build production assets
./Terminal/dev.sh build

# Process:
# 1. composer install --no-dev --optimize-autoloader
# 2. npm ci --production  
# 3. npm run build
# 4. php artisan config:cache
# 5. php artisan route:cache
# 6. php artisan view:cache
```

### 🌐 **Domain Setup**

Setup production domain:

```bash
# Add production domain dengan SSL
./Terminal/domain.sh add myapp.com awesome-app production

# Features:
# ✅ Auto-SSL (Let's Encrypt)
# ✅ Security headers  
# ✅ Gzip compression
# ✅ Static file caching
# ✅ Rate limiting
```

### 🚀 **Deployment**

Deploy ke production:

```bash
# Deploy dengan safety checks
./Terminal/deploy.sh deploy awesome-app production

# Deployment process:
# 1. Pre-deployment checks
# 2. Create backup
# 3. Build production assets
# 4. Optimize Laravel  
# 5. Run migrations
# 6. Restart services
# 7. Health checks
# 8. DNS/SSL verification
```

## 💡 Best Practices

### 🎯 **Project Organization**

```bash
# Naming conventions:
main-app          # Main application
api-backend       # API services  
admin-panel       # Admin interface
client-portal     # Client-facing app
mobile-api        # Mobile API
```

### 📦 **Dependencies Management**

```bash
# Per-project dependencies
cd Projects/awesome-app
./Terminal/composer.sh require laravel/telescope --dev

cd Projects/api-backend  
./Terminal/composer.sh require tymon/jwt-auth

# Dependencies terisolasi per project!
```

### 🗄️ **Database Strategy**

```bash
# Database naming:
main_app          # untuk main-app project
api_backend       # untuk api-backend project
admin_panel       # untuk admin-panel project

# Shared database (jika diperlukan):
./Terminal/database.sh clone main-app shared_db
# Update .env di projects yang perlu share
```

### 🔄 **Development Workflow**

```bash
# Daily workflow:
1. ./Terminal/project.sh switch current-project
2. ./Terminal/dev.sh start  
3. ./Terminal/dev.sh open
4. # Code, code, code...
5. ./Terminal/dev.sh test
6. ./Terminal/database.sh backup current-project
7. ./Terminal/deploy.sh deploy current-project staging
```

## 🐛 Troubleshooting

### 🔧 **Common Issues**

**Project tidak terdeteksi:**
```bash
# Check Laravel project validity
ls -la Projects/my-project/artisan  # File harus ada

# Re-scan projects  
./Terminal/project.sh list
```

**Port conflicts:**
```bash
# Check port assignment
./Terminal/project.sh list

# Release stuck ports
./Terminal/project.sh delete stuck-project
./Terminal/project.sh new fresh-project
```

**Database issues:**
```bash
# Check database connection
./Terminal/database.sh list

# Recreate database  
./Terminal/database.sh create project_name
```

**File permissions:**
```bash
# Fix permissions
docker exec -it laravel_frankenphp bash
chown -R www-data:www-data /var/www/html/projects
chmod -R 775 /var/www/html/projects/*/storage
```

### 📞 **Getting Help**

```bash
# Project-specific help
./Terminal/project.sh help

# Development help
./Terminal/dev.sh help

# Check project status
./Terminal/project.sh status project-name
./Terminal/dev.sh status
```

---

<div align="center">

**🎉 Happy Multi-Project Development! 🎉**

**Created with ❤️ by [Denis Djodian Ardika](https://github.com/denis156)**

**Leader & Founder of [Artelia.Dev](https://artelia.dev)**

[![GitHub](https://img.shields.io/badge/Follow-denis156-black?style=social&logo=github)](https://github.com/denis156)
[![Artelia.Dev](https://img.shields.io/badge/Visit-Artelia.Dev-orange?style=social&logo=dev.to)](https://artelia.dev)

*"One container, unlimited Laravel projects!"*

</div>
# ⚙️ Supervisor Documentation

<div align="center">

<img src="../Image/Logo-ArteliaDev-rounded.png" width="200" alt="Artelia.Dev Logo">

[![Supervisor](https://img.shields.io/badge/Supervisor-Process%20Manager-green?style=for-the-badge&logo=linux)](https://github.com/denis156/LaravelProjectContainer)
[![Background Jobs](https://img.shields.io/badge/Background-Jobs-blue?style=for-the-badge&logo=clockwise)](https://github.com/denis156/LaravelProjectContainer)
[![Monitoring](https://img.shields.io/badge/24/7-Monitoring-orange?style=for-the-badge&logo=grafana)](https://github.com/denis156/LaravelProjectContainer)
[![Artelia.Dev](https://img.shields.io/badge/Artelia.Dev-Denis%20Djodian%20Ardika-red?style=for-the-badge&logo=dev.to)](https://artelia.dev)

**Created by [Denis Djodian Ardika](https://github.com/denis156) - Artelia.Dev**

</div>

> **⚙️ Background Process Management yang Never Sleep!** - Supervisor yang mengawasi semua background processes dengan cinta dan perhatian!

## 🌟 Overview

Supervisor adalah jantung dari background process management di LaravelProjectContainer! Dengan sistem yang cerdas, Supervisor:

- 🔄 **Auto-restart** failed processes
- 📊 **Monitor** process health 24/7
- 🚀 **Manage** Laravel queues, schedulers, dan workers
- 📝 **Log** semua activities untuk debugging
- ⚡ **Scale** processes sesuai kebutuhan

## 📦 Configuration Structure

```
Supervisor/
├── supervisor.conf              # Main configuration file
└── Projects/                   # Auto-generated project configs
    ├── awesome-app.conf        # Config untuk awesome-app
    ├── api-backend.conf        # Config untuk api-backend
    └── admin-panel.conf        # Config untuk admin-panel
```

## 🎯 Process Types

### 🚀 **Laravel Queue Workers**

Handle background job processing:

```ini
[program:awesome-app-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/Projects/awesome-app/artisan queue:work --sleep=3 --tries=3 --max-time=3600
directory=/var/www/html/Projects/awesome-app
autostart=true
autorestart=true
startretries=3
user=www-data
numprocs=2                      # 2 worker processes
redirect_stderr=true
stdout_logfile=/var/log/laravel/awesome-app-worker.log
killasgroup=true
priority=999
```

**🎪 Features:**
- ✅ Multiple worker processes per project
- ✅ Auto-restart jika crash
- ✅ Memory limit protection
- ✅ Graceful shutdown support
- ✅ Per-project log files

### 📅 **Laravel Scheduler**

Handle cron jobs dan scheduled tasks:

```ini
[program:awesome-app-scheduler]
process_name=%(program_name)s
command=/bin/bash -c "while true; do php /var/www/html/Projects/awesome-app/artisan schedule:run --verbose --no-interaction; sleep 60; done"
directory=/var/www/html/Projects/awesome-app
autostart=true
autorestart=true
startretries=3
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/laravel/awesome-app-scheduler.log
stopwaitsecs=10
priority=997
```

**🎪 Features:**
- ✅ Run setiap menit (Laravel standard)
- ✅ Verbose output untuk debugging
- ✅ Isolated per project
- ✅ Graceful task handling

### 🌊 **Laravel Horizon** (Redis Queue Dashboard)

Advanced queue management dengan dashboard:

```ini
[program:awesome-app-horizon]
process_name=%(program_name)s
command=php /var/www/html/Projects/awesome-app/artisan horizon
directory=/var/www/html/Projects/awesome-app
autostart=false                # Manual start when needed
autorestart=true
startretries=3
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/laravel/awesome-app-horizon.log
stopwaitsecs=30
priority=996
```

### 🌐 **WebSocket Servers**

Real-time communication support:

```ini
# Laravel WebSockets
[program:awesome-app-websockets]
process_name=%(program_name)s
command=php /var/www/html/Projects/awesome-app/artisan websockets:serve
directory=/var/www/html/Projects/awesome-app
autostart=false
autorestart=true
startretries=3
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/laravel/awesome-app-websockets.log
stopwaitsecs=10
priority=995

# Laravel Reverb (Laravel 11+)
[program:awesome-app-reverb]
process_name=%(program_name)s
command=php /var/www/html/Projects/awesome-app/artisan reverb:start
directory=/var/www/html/Projects/awesome-app
autostart=false
autorestart=true
startretries=3
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/laravel/awesome-app-reverb.log
stopwaitsecs=10
priority=994
```

### ⚡ **Laravel Octane** (High Performance)

Super fast PHP application server:

```ini
[program:awesome-app-octane]
process_name=%(program_name)s
command=php /var/www/html/Projects/awesome-app/artisan octane:start --server=swoole --host=0.0.0.0 --port=8000
directory=/var/www/html/Projects/awesome-app
autostart=false
autorestart=true
startretries=3
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/laravel/awesome-app-octane.log
stopwaitsecs=30
priority=993
```

## 🎛️ Process Management

### 🚀 **Starting Processes**

```bash
# Start semua processes untuk project
supervisorctl start awesome-app:*

# Start specific process type
supervisorctl start awesome-app-worker:*
supervisorctl start awesome-app-scheduler

# Start individual worker
supervisorctl start awesome-app-worker:awesome-app-worker_00
```

### ⏹️ **Stopping Processes**

```bash
# Stop semua processes untuk project
supervisorctl stop awesome-app:*

# Stop specific process type
supervisorctl stop awesome-app-worker:*

# Graceful shutdown (recommended)
supervisorctl stop awesome-app-worker:* && sleep 5
```

### 🔄 **Restarting Processes**

```bash
# Restart semua processes
supervisorctl restart awesome-app:*

# Restart workers (untuk deploy baru)
supervisorctl restart awesome-app-worker:*

# Restart individual process
supervisorctl restart awesome-app-scheduler
```

### 📊 **Monitoring Status**

```bash
# Status semua processes
supervisorctl status

# Status untuk specific project
supervisorctl status awesome-app:*

# Detailed status dengan process info
supervisorctl status awesome-app-worker:*

# Output example:
# awesome-app-worker:awesome-app-worker_00   RUNNING   pid 1234, uptime 0:05:12
# awesome-app-worker:awesome-app-worker_01   RUNNING   pid 1235, uptime 0:05:12
# awesome-app-scheduler                      RUNNING   pid 1236, uptime 0:05:10
```

## 📊 System Monitoring

### 💓 **Health Monitoring**

Built-in health checks untuk semua processes:

```ini
[program:health-checker]
process_name=%(program_name)s
command=/bin/bash -c "while true; do curl -f http://localhost/health || echo 'Health check failed'; sleep 30; done"
autostart=true
autorestart=true
startretries=3
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/laravel/health-checker.log
priority=991
```

### 🔄 **Auto Log Rotation**

Prevent disk space issues:

```ini
[program:log-rotator]
process_name=%(program_name)s
command=/bin/bash -c "while true; do find /var/log/laravel -name '*.log' -size +100M -exec truncate -s 0 {} \; ; sleep 3600; done"
autostart=true
autorestart=true
startretries=3
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/supervisor/log-rotator.log
priority=990
```

### 📡 **Service Monitoring**

Monitor external services:

```ini
# Redis Monitor
[program:redis-monitor]
process_name=%(program_name)s
command=/bin/bash -c "while true; do redis-cli -h redis ping > /dev/null || echo 'Redis connection failed'; sleep 15; done"
autostart=true
autorestart=true
startretries=3
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/laravel/redis-monitor.log
priority=988

# Database Monitor
[program:database-monitor]
process_name=%(program_name)s
command=/bin/bash -c "while true; do mysqladmin -h mysql -u laravel -p'laravel' ping > /dev/null || echo 'Database connection failed'; sleep 30; done"
autostart=true
autorestart=true
startretries=3
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/laravel/database-monitor.log
priority=987
```

## 🎪 Process Groups

Organized management dengan groups:

```ini
# Queue Workers Group
[group:laravel-queues]
programs=awesome-app-worker,api-backend-worker,admin-panel-worker
priority=999

# Laravel Services Group  
[group:laravel-services]
programs=awesome-app-scheduler,awesome-app-horizon,awesome-app-websockets
priority=995

# System Monitoring Group
[group:monitoring]
programs=health-checker,log-rotator,redis-monitor,database-monitor
priority=990

# Development Tools Group
[group:development]
programs=file-watcher
priority=985
```

### 🎯 **Group Management**

```bash
# Start entire group
supervisorctl start laravel-queues:*

# Stop entire group
supervisorctl stop laravel-services:*

# Restart monitoring group
supervisorctl restart monitoring:*

# Status by group
supervisorctl status laravel-queues:*
```

## 📊 Logging & Debugging

### 📝 **Log Files Structure**

```
/var/log/laravel/
├── awesome-app-worker.log       # Queue worker logs
├── awesome-app-scheduler.log    # Scheduler logs  
├── awesome-app-horizon.log      # Horizon dashboard logs
├── awesome-app-websockets.log   # WebSocket server logs
├── health-checker.log           # Health monitoring
├── redis-monitor.log            # Redis connectivity
└── database-monitor.log         # Database connectivity

/var/log/supervisor/
├── supervisord.log              # Main supervisor log
├── log-rotator.log              # Log rotation activities
└── crashes/                     # Crash reports
```

### 🔍 **Debugging Commands**

```bash
# View real-time logs
tail -f /var/log/laravel/awesome-app-worker.log

# View scheduler logs
tail -f /var/log/laravel/awesome-app-scheduler.log

# View all logs combined
tail -f /var/log/laravel/*.log

# Search for errors
grep "ERROR" /var/log/laravel/awesome-app-worker.log

# View last 100 lines
tail -n 100 /var/log/laravel/awesome-app-worker.log
```

### 🚨 **Error Handling**

Built-in error monitoring:

```ini
[eventlistener:crashmail]
command=/var/www/html/Terminal/notify-crash.sh
events=PROCESS_STATE_EXITED
buffer_size=100
directory=/var/www/html/Terminal
autostart=true
autorestart=unexpected
priority=986

[eventlistener:memmon]
command=/var/www/html/Terminal/memory-monitor.sh
events=TICK_60
buffer_size=100
directory=/var/www/html/Terminal
autostart=true
autorestart=unexpected
priority=985
```

## 🔧 Configuration Management

### 🆕 **Auto-Generated Configs**

Saat project baru dibuat:

```bash
# Project creation triggers auto-config generation
./Terminal/project.sh new my-new-app

# Generated config: /etc/supervisor/conf.d/Projects/my-new-app.conf
# Contains:
# - Queue workers (2 processes)
# - Task scheduler (1 process)  
# - Optional services (Horizon, WebSockets, etc.)
```

### ⚙️ **Custom Configuration**

Edit project-specific supervisor config:

```bash
# Edit project supervisor config
nano /etc/supervisor/conf.d/Projects/awesome-app.conf

# Update supervisor dengan perubahan
supervisorctl reread
supervisorctl update

# Restart affected processes
supervisorctl restart awesome-app:*
```

### 🎛️ **Process Scaling**

Scale workers based pada load:

```bash
# Edit config untuk scale workers
[program:awesome-app-worker]
numprocs=4                      # Increase dari 2 ke 4 workers

# Apply changes
supervisorctl reread
supervisorctl update
supervisorctl restart awesome-app-worker:*

# Verify scaling
supervisorctl status awesome-app-worker:*
# Output:
# awesome-app-worker:awesome-app-worker_00   RUNNING
# awesome-app-worker:awesome-app-worker_01   RUNNING  
# awesome-app-worker:awesome-app-worker_02   RUNNING
# awesome-app-worker:awesome-app-worker_03   RUNNING
```

## 🚀 Performance Optimization

### ⚡ **Worker Optimization**

Optimal settings untuk different workloads:

```ini
# High-throughput workers
[program:api-backend-worker]
command=php artisan queue:work --sleep=1 --tries=3 --max-time=1800
numprocs=4
priority=998

# Background processing workers  
[program:admin-panel-worker]
command=php artisan queue:work --sleep=5 --tries=1 --max-time=3600
numprocs=1
priority=1000

# Priority queue workers
[program:awesome-app-worker-high]
command=php artisan queue:work --queue=high --sleep=1 --tries=3 --max-time=3600
numprocs=1
priority=998
```

### 📊 **Memory Management**

Prevent memory leaks:

```ini
[program:awesome-app-worker]
command=php artisan queue:work --sleep=3 --tries=3 --max-time=3600 --memory=128
# Auto-restart worker setelah process 100 jobs
command=php artisan queue:work --sleep=3 --tries=3 --max-jobs=100
```

### 🔄 **Process Priorities**

Ensure critical processes run first:

```ini
# Priority levels (lower = higher priority):
priority=990    # System monitoring (highest)
priority=995    # Laravel services  
priority=997    # Schedulers
priority=999    # Queue workers (lowest)
```

## 🎯 Production Configuration

### 🚀 **Production Optimizations**

```ini
# Production worker config
[program:production-app-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/Projects/production-app/artisan queue:work redis --sleep=1 --tries=3 --max-time=1800 --max-jobs=1000
directory=/var/www/html/Projects/production-app
autostart=true
autorestart=true
startretries=5
user=www-data
numprocs=8                      # Scale untuk production load
redirect_stderr=true
stdout_logfile=/var/log/laravel/production-app-worker.log
stdout_logfile_maxbytes=100MB
stdout_logfile_backups=10
killasgroup=true
priority=999
```

### 📊 **Production Monitoring**

Enhanced monitoring untuk production:

```ini
# Enhanced health checker
[program:production-health-checker]
command=/bin/bash -c "while true; do curl -f https://myapp.com/health && curl -f https://api.myapp.com/health || echo 'Production health check failed'; sleep 10; done"
autostart=true
autorestart=true
startretries=10
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/laravel/production-health.log
priority=990

# Resource monitoring
[program:resource-monitor]
command=/bin/bash -c "while true; do echo 'CPU:' $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}') 'MEM:' $(free | grep Mem | awk '{printf(\"%.2f%%\", $3/$2 * 100.0)}'); sleep 60; done"
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/laravel/resource-monitor.log
priority=991
```

## 🛠️ Troubleshooting

### 🔧 **Common Issues**

**Process won't start:**
```bash
# Check configuration syntax
supervisorctl reread

# Check logs untuk error details
tail -f /var/log/supervisor/supervisord.log

# Verify file permissions
ls -la /var/www/html/Projects/awesome-app/artisan
chown -R www-data:www-data /var/www/html/Projects/
```

**High memory usage:**
```bash
# Check process memory usage
supervisorctl status awesome-app-worker:*

# Add memory limits
command=php artisan queue:work --memory=128

# Restart workers regularly
command=php artisan queue:work --max-jobs=100
```

**Process keeps crashing:**
```bash
# Check error logs
tail -f /var/log/laravel/awesome-app-worker.log

# Check Laravel logs
tail -f /var/www/html/Projects/awesome-app/storage/logs/laravel.log

# Increase restart retries
startretries=10
```

**Database connection issues:**
```bash
# Check database connectivity
./Terminal/database.sh list

# Restart database container
docker-compose restart mysql

# Check Laravel database config
cat /var/www/html/Projects/awesome-app/.env | grep DB_
```

### 🚨 **Emergency Commands**

```bash
# Stop all processes (emergency)
supervisorctl stop all

# Start essential services only
supervisorctl start monitoring:*
supervisorctl start laravel-queues:*

# Restart supervisor daemon
service supervisor restart

# Check supervisor daemon status
service supervisor status
```

## 💡 Best Practices

### 🎯 **Development Practices**

```bash
# Always check status after changes
supervisorctl reread && supervisorctl update
supervisorctl status

# Use groups untuk bulk operations
supervisorctl restart laravel-queues:*

# Monitor logs during development
tail -f /var/log/laravel/awesome-app-worker.log

# Test worker code before deployment
php /var/www/html/Projects/awesome-app/artisan queue:work --once
```

### 🚀 **Production Practices**

```bash
# Graceful deployment process:
1. supervisorctl stop awesome-app-worker:*
2. # Deploy new code
3. php artisan queue:restart
4. supervisorctl start awesome-app-worker:*

# Monitor after deployment
supervisorctl status awesome-app:*
tail -f /var/log/laravel/awesome-app-worker.log

# Scale workers based on queue size
php artisan queue:size
# If queue is large, increase numprocs
```

### 📊 **Monitoring Practices**

```bash
# Regular health checks
supervisorctl status | grep -v RUNNING

# Check log file sizes
du -sh /var/log/laravel/*.log

# Monitor queue depth
php artisan queue:size

# Check failed jobs
php artisan queue:failed
```

## 🎪 Integration dengan Terminal Scripts

### 🔄 **Automatic Integration**

Terminal scripts otomatis manage supervisor:

```bash
# Project creation
./Terminal/project.sh new myapp
# → Auto-generates supervisor config
# → Auto-starts workers dan scheduler

# Development workflow
./Terminal/dev.sh start
# → Starts all supervisor processes untuk current project

# Deployment
./Terminal/deploy.sh deploy myapp production  
# → Gracefully restarts workers
# → Ensures zero-downtime deployment
```

### 📊 **Status Integration**

```bash
# Project status includes supervisor info
./Terminal/project.sh status myapp

# Development status includes process monitoring
./Terminal/dev.sh status

# Deployment includes process health checks
./Terminal/deploy.sh status myapp production
```

---

<div align="center">

**⚙️ Supervisor: The Silent Guardian of Your Processes! ⚙️**

**Created with ❤️ by [Denis Djodian Ardika](https://github.com/denis156)**

**Leader & Founder of [Artelia.Dev](https://artelia.dev)**

[![GitHub](https://img.shields.io/badge/Follow-denis156-black?style=social&logo=github)](https://github.com/denis156)
[![Artelia.Dev](https://img.shields.io/badge/Visit-Artelia.Dev-orange?style=social&logo=dev.to)](https://artelia.dev)

*"Processes that never sleep, monitoring that never stops!"*

</div>
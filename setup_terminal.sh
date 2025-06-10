#!/bin/bash

# ===============================================
# LaravelProjectContainer - Terminal Setup Script
# ===============================================
# Make all terminal scripts executable & create aliases
# Created by Denis Djodian Ardika - Artelia.Dev
# ===============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${WHITE}  LaravelProjectContainer Setup${NC}"
    echo -e "${CYAN}  by Denis Djodian Ardika - Artelia.Dev${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header

print_info "Setting up terminal scripts permissions..."

# Check if terminal directory exists
if [ ! -d "Terminal" ]; then
    echo -e "${RED}✗ Terminal directory not found!${NC}"
    echo -e "${YELLOW}Make sure you're in the LaravelProjectContainer root directory${NC}"
    exit 1
fi

# Get current directory
CURRENT_DIR=$(pwd)

# Make all shell scripts executable
print_info "Making terminal scripts executable..."

chmod +x Terminal/project.sh && print_success "project.sh - Project management"
chmod +x Terminal/dev.sh && print_success "dev.sh - Development workflow"
chmod +x Terminal/artisan.sh && print_success "artisan.sh - Laravel Artisan shortcuts"
chmod +x Terminal/composer.sh && print_success "composer.sh - Composer management"
chmod +x Terminal/database.sh && print_success "database.sh - Database operations"
chmod +x Terminal/domain.sh && print_success "domain.sh - Domain & SSL management"
chmod +x Terminal/deploy.sh && print_success "deploy.sh - Production deployment"

# Create global aliases
print_info "Creating global command aliases..."

# Create bin directory
mkdir -p bin

# Create wrapper scripts
cat > bin/project << EOF
#!/bin/bash
cd "$CURRENT_DIR" && ./Terminal/project.sh "\$@"
EOF

cat > bin/dev << EOF
#!/bin/bash
cd "$CURRENT_DIR" && ./Terminal/dev.sh "\$@"
EOF

cat > bin/artisan << EOF
#!/bin/bash
cd "$CURRENT_DIR" && ./Terminal/artisan.sh "\$@"
EOF

cat > bin/composer-laravel << EOF
#!/bin/bash
cd "$CURRENT_DIR" && ./Terminal/composer.sh "\$@"
EOF

cat > bin/database << EOF
#!/bin/bash
cd "$CURRENT_DIR" && ./Terminal/database.sh "\$@"
EOF

cat > bin/domain << EOF
#!/bin/bash
cd "$CURRENT_DIR" && ./Terminal/domain.sh "\$@"
EOF

cat > bin/deploy << EOF
#!/bin/bash
cd "$CURRENT_DIR" && ./Terminal/deploy.sh "\$@"
EOF

# Make wrapper scripts executable
chmod +x bin/*

print_success "Global command wrappers created!"

# Verify permissions
print_info "Verifying permissions..."
if ls -la Terminal/*.sh | grep -q "rwxr-xr-x"; then
    print_success "All scripts are now executable!"
else
    print_warning "Some scripts might not have correct permissions"
fi

echo -e "\n${GREEN}🎉 Setup complete! Terminal scripts are ready to use!${NC}"
echo -e "\n${CYAN}Global Commands Available (after PATH setup):${NC}"
echo -e "${WHITE}project help${NC}                 # Project management"
echo -e "${WHITE}dev help${NC}                     # Development workflow"
echo -e "${WHITE}artisan help${NC}                 # Laravel Artisan shortcuts"
echo -e "${WHITE}composer-laravel help${NC}        # Composer management"
echo -e "${WHITE}database help${NC}                # Database operations"
echo -e "${WHITE}domain help${NC}                  # Domain & SSL management"
echo -e "${WHITE}deploy help${NC}                  # Production deployment"

echo -e "\n${CYAN}Quick test (current method):${NC}"
echo -e "${WHITE}./Terminal/project.sh help${NC}"
echo -e "\n${CYAN}To enable global commands, run:${NC}"
echo -e "${WHITE}export PATH=\"$CURRENT_DIR/bin:\$PATH\"${NC}"
echo -e "\n${CYAN}Or add to your shell config (~/.zshrc or ~/.bashrc):${NC}"
echo -e "${WHITE}export PATH=\"$CURRENT_DIR/bin:\$PATH\"${NC}"
echo -e "\n${CYAN}Then reload shell:${NC}"
echo -e "${WHITE}source ~/.zshrc${NC}  # for zsh"
echo -e "${WHITE}source ~/.bashrc${NC} # for bash"

echo -e "\n${CYAN}Next steps:${NC}"
echo -e "1. ${WHITE}cp .env.example .env${NC}"
echo -e "2. ${WHITE}docker-compose up -d${NC}"
echo -e "3. ${WHITE}./Terminal/project.sh new my-awesome-app${NC} (or ${WHITE}project new my-awesome-app${NC} after PATH setup)"

echo -e "\n${YELLOW}Happy coding! 🚀${NC}"
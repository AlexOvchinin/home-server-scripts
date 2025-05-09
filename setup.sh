#!/bin/bash

# Service Manager Script
# Configs are located in the same directory as this script

# Configuration
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_DIR="$SOURCE_DIR/docker"
CONFIG_DIR="$SOURCE_DIR/configs"  # Configs stored in subdirectory of script location
APPS_DIR="/hot/apps"      # Where symlinks will be created
LOG_FILE="$SOURCE_DIR/service-manager.log"

# Initialize logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Help function
show_help() {
    echo "Usage: $0 [command] [options]"
    echo "Commands:"
    echo "  update-configs    - Update service configurations by creating symlinks"
    echo "  launch-all        - Launch all service"
    echo "  restart-all       - Restart all services"
    echo "  restart <service> - Restart a specific service"
    echo "  status            - Show status of all services"
    echo "  help              - Show this help message"
}

# Verify and prepare environment
setup_environment() {
    # Create target directory if missing
    if [ ! -d "$APPS_DIR" ]; then
        log "Creating target directory: $APPS_DIR"
        mkdir -p "$APPS_DIR" || {
            log "ERROR: Failed to create target directory"
            exit 1
        }
    fi
}

update_homepage() {
    log "Updating homepage"
    rm -rf "$APPS_DIR/homepage/*"
    rm -rf "$APPS_DIR/homepage"
    mkdir "$APPS_DIR/homepage"
    cp -r "$SOURCE_DIR/apps/homepage/configs" "$APPS_DIR/homepage/configs"
    ln -s "$SOURCE_DIR/apps/homepage/images" "$APPS_DIR/homepage/images"
    ln -s "$SOURCE_DIR/apps/homepage/docker-compose.yaml" "$APPS_DIR/homepage/docker-compose.yaml"
    log "Finished updating homepage"
}

# Update configurations by creating symlinks
update() {
    log "Starting configuration update..."
    log "Creating apps folder"
    mkdir "$APPS_DIR"
    update_homepage
    log "Creating portainer symbolic link"
    ln -s "$SOURCE_DIR/apps/portainer" "$APPS_DIR/portainer"
    log "Create nginx conf symbolic link"
    ln -s "$SOURCE_DIR/apps/nginx/main.conf" "/etc/nginx/conf.d/main.conf"
    log "Configuration updated finished"
}

restart_nginx() {
    log "Restating nginx"
    systemctl restart nginx
    log "Finished restarting nginx"
}

restart_docker_service() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        log "ERROR: Service name not specified"
        return 1
    fi

    log "Restarting $service_name"
    docker compose -f "$APPS_DIR/$service_name/docker-compose.yaml" up -d --force-recreate
}

# Restart all services
restart_all() {
    log "Restarting all services..."
    restart_nginx
    restart_docker_service "homepage"
    restart_docker_service "portainer"
    log "All services restarted."
}

# Restart specific service
restart_service() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        log "ERROR: Service name not specified"
        return 1
    fi
    
    log "Restarting service: $service_name"

    case "$1" in
        nginx)
            restart_nginx
            ;;
        homepage|portainer)
            restart_docker_service $service_name
            ;;
        *)
            log "Unknown service $service_name"
            exit 1
    esac
    # Example implementation:
    # if [ -f "$APPS_DIR/$service_name.conf" ]; then
    #     systemctl restart "$service_name"
    # else
    #     log "ERROR: Service $service_name not found"
    #     return 1
    # fi
}

# Show status of all services
show_status() {
    log "Current service status:"
    docker ps
    systemctl status nginx
    # Example implementation:
    # while read -r config; do
    #     local service=$(basename "$config" .conf)
    #     systemctl status "$service" --no-pager -l
    # done < <(ls "$APPS_DIR"/*.conf)
}

# Main command processor
main() {
    case "$1" in
        update)
            update
            ;;
        restart-all)
            restart_all
            ;;
        restart)
            restart_service "$2"
            ;;
        status)
            show_status
            ;;
        help|--help|-h|"")
            show_help
            ;;
        *)
            log "ERROR: Unknown command '$1'"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"
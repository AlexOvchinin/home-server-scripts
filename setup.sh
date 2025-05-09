#!/bin/bash

# Service Manager Script
# Configs are located in the same directory as this script

# Configuration
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_DIR="$SOURCE_DIR/docker"
CONFIG_DIR="$SOURCE_DIR/configs"  # Configs stored in subdirectory of script location
TARGET_DIR="/hot/apps"      # Where symlinks will be created
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
    if [ ! -d "$TARGET_DIR" ]; then
        log "Creating target directory: $TARGET_DIR"
        mkdir -p "$TARGET_DIR" || {
            log "ERROR: Failed to create target directory"
            exit 1
        }
    fi
}

# Update configurations by creating symlinks
update() {
    echo "Starting configuration update..."
    ln -s "$SOURCE_DIR/apps" "$TARGET_DIR"
    echo "Configuration updated finished"
}

# Restart all services
restart_all() {
    log "Restarting all services..."
    docker compose -f "$TARGET_DIR/apps/gethomepage/docker-compose.yaml" up -d
    log "All services restarted."
}

launch_all() {
    echo "Launching all services"
    echo "Launching home page"
    docker compose -f "$DOCKER_COMPOSE_DIR/gethomepage/docker-compose.yaml" up -d
    echo "All service launched"
}

# Restart specific service
restart_service() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        log "ERROR: Service name not specified"
        return 1
    fi
    
    log "Restarting service: $service_name"
    # Example implementation:
    # if [ -f "$TARGET_DIR/$service_name.conf" ]; then
    #     systemctl restart "$service_name"
    # else
    #     log "ERROR: Service $service_name not found"
    #     return 1
    # fi
}

# Show status of all services
show_status() {
    log "Current service status:"
    # Example implementation:
    # while read -r config; do
    #     local service=$(basename "$config" .conf)
    #     systemctl status "$service" --no-pager -l
    # done < <(ls "$TARGET_DIR"/*.conf)
}

# Main command processor
main() {
    case "$1" in
        update)
            update
            ;;
        launch-all)
            launch_all
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
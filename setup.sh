#!/bin/bash

# Service Manager Script
# Configs are located in the same directory as this script

# Configuration
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_DIR="$SOURCE_DIR/docker"
CONFIG_DIR="$SOURCE_DIR/configs"  # Configs stored in subdirectory of script location
APPS_DIR="/hot/apps"      # Where symlinks will be created

# Initialize logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Help function
show_help() {
    echo "Usage: $0 [command] [options]"
    echo "Commands:"
    echo "  update            - Update all service configurations by creating symlinks"
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
    if [ ! -d "$APPS_DIR/homepage" ]; then
        mkdir "$APPS_DIR/homepage" && mkdir "$APPS_DIR/homepage/configs"
    fi
    cp -r -v "$SOURCE_DIR/apps/homepage/configs/" "$APPS_DIR/homepage/"
    cp -r -v "$SOURCE_DIR/apps/homepage/images/" "$APPS_DIR/homepage/"
    ln -s "$SOURCE_DIR/apps/homepage/docker-compose.yaml" "$APPS_DIR/homepage/docker-compose.yaml"
    log "Finished updating homepage"
}

update_jellyfin() {
    log "Updating jellyfin"
    if [ ! -d "$APPS_DIR/jellyfin" ]; then
        mkdir "$APPS_DIR/jellyfin" && mkdir "$APPS_DIR/jellyfin/config" && mkdir "$APPS_DIR/jellyfin/cache"
    fi
    log "Creating docker compose symlink"
    if [ ! -d "$APPS_DIR/jellyfin/docker-compose.yaml" ]; then
        ln -s "$SOURCE_DIR/apps/jellyfin/docker-compose.yaml" "$APPS_DIR/jellyfin/docker-compose.yaml"
    fi
    log "Finished updating jellyfin"
}

update_immich() {
    log "Updating immich"
    if [ ! -d "$APPS_DIR/immich" ]; then
        mkdir "$APPS_DIR/immich" && mkdir "$APPS_DIR/immich/postgres"
    fi
    log "Creating docker compose symlink"
    if [ ! -d "$APPS_DIR/immich/docker-compose.yaml" ]; then
        ln -s "$SOURCE_DIR/apps/immich/docker-compose.yaml" "$APPS_DIR/immich/docker-compose.yaml"
    fi
    log "Creating .env link"
    if [ ! -d "$APPS_DIR/immich/.env" ]; then
        ln -s "$SOURCE_DIR/apps/immich/.env" "$APPS_DIR/immich/.env"
    fi
    log "Finished updating immich"
}

update_samba() {
    log "Updating samba"
    if [ ! -d "/etc/samba/smb.conf" ]; then
        log "Creating symlink for configuration"
        ln -s "$SOURCE_DIR/apps/samba/smb.conf" "/etc/samba/smb.conf"
    fi
    log "Finished updating samba"
}

update_flood() {
    log "Updating flood"
    log "Create config folders"
    if [ ! -d "$APPS_DIR/flood" ]; then
        mkdir "$APPS_DIR/flood"
    fi
    if [ ! -d "$APPS_DIR/flood/config" ]; then
        mkdir "$APPS_DIR/flood/config"
    fi
    log "Finished updating flood"
}

update_transmission() {
    log "Updating transmission"
    log "Create config folders"
    if [ ! -d "$APPS_DIR/transmission" ]; then
        mkdir "$APPS_DIR/transmission"
    fi
    if [ ! -d "$APPS_DIR/transmission/config" ]; then
        mkdir "$APPS_DIR/transmission/config"
    fi
    log "Create docker compose symlink"
    ln -snf "$SOURCE_DIR/apps/transmission/docker-compose.yaml" "$APPS_DIR/transmission/docker-compose.yaml"
    log "Finished updating transmission"
}

# Update configurations by creating symlinks
update() {
    log "Starting configuration update..."
    log "Creating apps folder"
    if [ ! -d "$APPS_DIR" ]; then
        mkdir "$APPS_DIR"
    fi
    update_homepage
    log "Creating portainer symbolic link"
    ln -sfn "$SOURCE_DIR/apps/portainer" "$APPS_DIR/portainer"
    log "Create nginx conf symbolic link"
    ln -s "$SOURCE_DIR/apps/nginx/main.conf" "/etc/nginx/conf.d/main.conf"
    update_jellyfin
    update_samba
    update_transmission
    update_immich
    log "Configuration updated finished"
}

restart_nginx() {
    log "Restating nginx"
    systemctl restart nginx
    sudo systemctl status nginx
    log "Finished restarting nginx"
}

restart_samba() {
    log "Restaring samba"
    sudo systemctl restart smbd
    sudo systemctl status smbd
    sudo systemctl restart wsdd-server
    sudo systemctl status wsdd-server
    log "Finished restarting samba"
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
    restart_samba
    restart_docker_service "homepage"
    restart_docker_service "portainer"
    restart_docker_service "jellyfin"
    restart_docker_service "transmission"
    restart_docker_service "immich"
    sudo docker ps
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
        samba)
            restart_samba
            ;;
        homepage|portainer|jellyfin|transmission|immich)
            restart_docker_service $service_name
            ;;
        *)
            log "Unknown service $service_name"
            exit 1
    esac
}

# Show status of all services
show_status() {
    log "Current service status:"
    docker ps
    systemctl status nginx
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
#!/bin/bash

function launch_app() {
    if [ -z "$1" ]; then
        echo "Usage: launch_app <app_name>"
        return 1
    fi
    
    local app_name="$1"
    echo "Launching $app_name..."
    open -a "$app_name" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully launched $app_name"
    else
        echo "❌ Failed to launch $app_name. App may not be installed."
    fi
}

function quit_app() {
    if [ -z "$1" ]; then
        echo "Usage: quit_app <app_name>"
        return 1
    fi
    
    local app_name="$1"
    echo "Quitting $app_name..."
    osascript -e "quit app \"$app_name\"" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully quit $app_name"
    else
        echo "❌ Failed to quit $app_name. App may not be running."
    fi
}

function delete_app() {
    if [ -z "$1" ]; then
        echo "Usage: delete_app <app_name>"
        return 1
    fi
    
    local app_name="$1"
    local app_path="/Applications/$app_name.app"
    
    if [ -d "$app_path" ]; then
        echo "Are you sure you want to delete $app_name? (y/N)"
        read -r confirmation
        if [[ $confirmation =~ ^[Yy]$ ]]; then
            echo "Deleting $app_name..."
            rm -rf "$app_path"
            if [ $? -eq 0 ]; then
                echo "✅ Successfully deleted $app_name"
            else
                echo "❌ Failed to delete $app_name. Check permissions."
            fi
        else
            echo "❌ Deletion cancelled."
        fi
    else
        echo "❌ App $app_name not found in /Applications/"
    fi
}

function show_help() {
    echo "App Manager Script"
    echo "=================="
    echo "Usage:"
    echo "  ./app_manager.sh launch <app_name>    - Launch an application"
    echo "  ./app_manager.sh quit <app_name>      - Quit an application"
    echo "  ./app_manager.sh delete <app_name>    - Delete an application"
    echo "  ./app_manager.sh help                 - Show this help"
    echo ""
    echo "Examples:"
    echo "  ./app_manager.sh launch Safari"
    echo "  ./app_manager.sh quit Safari"
    echo "  ./app_manager.sh delete Safari"
}

case "$1" in
    launch)
        launch_app "$2"
        ;;
    quit)
        quit_app "$2"
        ;;
    delete)
        delete_app "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Invalid command. Use 'help' for usage information."
        show_help
        exit 1
        ;;
esac
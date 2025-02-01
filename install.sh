#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if the script is run as root (for package installation)
if [[ $EUID -ne 0 ]]; then
    print_message "$YELLOW" "This script may require root privileges to install dependencies. Switching to sudo..."
    sudo "$0" "$@"
    exit $?
fi

# Install required system packages
install_dependencies() {
    print_message "$YELLOW" "Checking and installing required system packages..."

    # Update package list
    apt update || { print_message "$RED" "Failed to update package list."; exit 1; }

    # Install Python3, python3-venv, and python3-pip
    if ! command -v python3 &> /dev/null; then
        print_message "$YELLOW" "Python3 is not installed. Installing Python3..."
        apt install -y python3 || { print_message "$RED" "Failed to install Python3."; exit 1; }
    fi

    if ! python3 -m venv temp_venv_test &> /dev/null; then
        print_message "$YELLOW" "The 'python3-venv' package is not installed. Installing it now..."
        apt install -y python3-venv || { print_message "$RED" "Failed to install python3-venv."; exit 1; }
    fi

    if ! command -v pip &> /dev/null; then
        print_message "$YELLOW" "pip is not installed. Installing pip..."
        apt install -y python3-pip || { print_message "$RED" "Failed to install pip."; exit 1; }
    fi

    # Install development tools and libraries
    if ! dpkg -l | grep -q build-essential; then
        print_message "$YELLOW" "Development tools are not installed. Installing them now..."
        apt install -y build-essential python3-dev libffi-dev libssl-dev || { print_message "$RED" "Failed to install development tools."; exit 1; }
    fi

    print_message "$GREEN" "All required system packages are installed."
}

# Cleanup function for errors or interrupts
cleanup() {
    print_message "$RED" "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    exit 1
}

# Trap signals for cleanup
trap cleanup SIGINT SIGTERM ERR

# Start installation
print_message "$BLUE" "Starting installation..."

# Install dependencies if needed
install_dependencies

# Create temporary directory
TEMP_DIR=$(mktemp -d)
if [[ ! -d "$TEMP_DIR" ]]; then
    print_message "$RED" "Failed to create temporary directory."
    exit 1
fi
cd "$TEMP_DIR" || { print_message "$RED" "Failed to enter temporary directory."; exit 1; }

# Create virtual environment
print_message "$GREEN" "Creating virtual environment..."
python3 -m venv venv || { print_message "$RED" "Failed to create virtual environment."; cleanup; }

# Activate virtual environment
print_message "$GREEN" "Activating virtual environment..."
source venv/bin/activate || { print_message "$RED" "Failed to activate virtual environment."; cleanup; }

# Verify that pip is using the virtual environment
PIP_PATH=$(which pip)
if [[ "$PIP_PATH" != *"venv"* ]]; then
    print_message "$RED" "pip is not using the virtual environment. Path: $PIP_PATH"
    cleanup
else
    print_message "$GREEN" "pip is correctly using the virtual environment: $PIP_PATH"
fi

# Upgrade pip
print_message "$GREEN" "Upgrading pip..."
pip install --upgrade pip || { print_message "$RED" "Failed to upgrade pip."; cleanup; }

# Install required packages
print_message "$GREEN" "Installing required packages inside the virtual environment..."
pip install colorama netifaces ipaddress || { 
    print_message "$RED" "Failed to install required packages. Printing detailed error log:"
    pip install colorama netifaces ipaddress --verbose
    cleanup
}

# Verify installed packages
print_message "$GREEN" "Verifying installed packages in the virtual environment..."
pip list || { print_message "$RED" "Failed to verify installed packages."; cleanup; }

# Download source code
print_message "$GREEN" "Downloading source code..."
curl -fsSL https://raw.githubusercontent.com/Salarvand-Education/6to4/main/main.py -o main.py || { print_message "$RED" "Failed to download source code."; cleanup; }

# Run the program
print_message "$GREEN" "Running the program..."
python main.py || { print_message "$RED" "Failed to run the program."; cleanup; }

# Cleanup
print_message "$GREEN" "Cleaning up temporary files..."
cd ..
rm -rf "$TEMP_DIR"

print_message "$BLUE" "Operation completed successfully!"

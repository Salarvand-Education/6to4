#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting installation...${NC}"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Create virtual environment
echo -e "${GREEN}Creating virtual environment...${NC}"
python3 -m venv venv

# Activate virtual environment
echo -e "${GREEN}Activating virtual environment...${NC}"
source venv/bin/activate

# Upgrade pip
echo -e "${GREEN}Upgrading pip...${NC}"
pip install --upgrade pip

# Install required packages
echo -e "${GREEN}Installing required packages...${NC}"
pip install colorama netifaces ipaddress

# Download source code
echo -e "${GREEN}Downloading source code...${NC}"
curl -fsSL https://raw.githubusercontent.com/Salarvand-Education/6to4/main/main.py -o main.py

# Run the program
echo -e "${GREEN}Running the program...${NC}"
python main.py

# Cleanup
echo -e "${GREEN}Cleaning up temporary files...${NC}"
cd ..
rm -rf "$TEMP_DIR"

echo -e "${BLUE}Operation completed successfully!${NC}"

# Cleanup function for errors or interrupts
cleanup() {
    echo -e "${RED}Cleaning up...${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
}

# Register cleanup function for interruption signals
trap cleanup SIGINT SIGTERM ERR

#!/bin/bash
# filepath: ./install_miniconda.sh

# Check if conda is already installed and working
if command -v conda &> /dev/null; then
    echo "Conda is already installed and available in PATH"
    conda --version
    conda env list
    exit 0
fi

# Detect system architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
elif [ "$ARCH" = "aarch64" ]; then
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Download the Miniconda installer to ~/miniconda.sh
echo "Downloading Miniconda installer for $ARCH..."
wget $MINICONDA_URL -O ~/miniconda.sh

# Define conda installation directory
CONDA_DIR=$HOME/miniconda3

# Check if directory exists and remove if incomplete
if [ -d "$CONDA_DIR" ]; then
    echo "Removing incomplete conda installation..."
    rm -rf "$CONDA_DIR"
fi

# Install Miniconda silently (-b) to specified directory (-p)
echo "Installing Miniconda to $CONDA_DIR..."
bash ~/miniconda.sh -b -p $CONDA_DIR

# Set proper ownership
chown -R $USER:$USER $CONDA_DIR

# Update the PATH environment variable for the current session
export PATH=$CONDA_DIR/bin:$PATH

# Initialize conda for bash
echo "Initializing conda..."
$CONDA_DIR/bin/conda init bash

# Add conda to PATH in current session
export PATH=$CONDA_DIR/bin:$PATH

# Refresh the shell environment to apply changes
source ~/.bashrc

echo "Conda installation completed!"
echo "You may need to restart your terminal or run: source ~/.bashrc"
echo "To verify installation, run: conda --version"
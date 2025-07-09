#!/bin/bash
# This script creates a new conda environment with a user-defined name and Python 3.8

# terminate on any error
# set -e

# ===== create a new conda environment or activate an existing one =====
# Ensure conda is available
module load miniconda


echo "Creating or activating a conda environment..."
# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/conda_install/conda_env_create_activate.sh"
echo "Conda environment is ready."

# ===== test CUDA in the current conda environment =====
echo "Testing CUDA in the current conda environment..."
module load CUDA/12.6
module load GCC/13.3
source "$SCRIPT_DIR/ml_package_install.sh"


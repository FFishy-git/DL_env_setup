#!/bin/bash

# ask for the huggingface access token
read -p "Enter your huggingface access token: " HF_ACCESS_TOKEN

# configure git credential helper
git config --global credential.helper store

# login to huggingface
huggingface-cli login --token $HF_ACCESS_TOKEN --add-to-git-credential
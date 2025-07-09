#!/bin/bash

# Function to display a separator line
print_separator() {
  echo "------------------------------------------------------------------"
}

# List available conda environments
echo "Available conda environments:"
envs=($(conda env list | grep -v '#' | awk '{print $1}'))
if [ ${#envs[@]} -eq 0 ]; then
    echo "No conda environments found."
    exit 1
fi

# Display the list and prompt for selection
echo "Please select a conda environment:"
select env in "${envs[@]}"; do
    if [ -n "$env" ]; then
        CONDA_ENV_NAME="$env"
        echo "You selected: $CONDA_ENV_NAME"
        break
    else
        echo "Invalid selection. Try again."
    fi
done

# Activate the selected conda environment
echo "Activating the conda environment '$CONDA_ENV_NAME'..."
eval "$(conda shell.bash hook)"
conda activate "$CONDA_ENV_NAME"
if [ $? -ne 0 ]; then
    echo "Failed to activate the conda environment '$CONDA_ENV_NAME'."
    exit 1
fi
echo "Conda environment '$CONDA_ENV_NAME' is now active."

# --- Step 2: Run test for PyTorch GPU support ---
echo "Running PyTorch GPU support test..."

python -c "
import torch

if torch.cuda.is_available():
    print('✅ PyTorch GPU support is enabled.')
    print(f'CUDA version: {torch.version.cuda}')
    print(f'Number of GPUs: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'  GPU {i}: {torch.cuda.get_device_name(i)}')
else:
    print('❌ PyTorch GPU support is not available.')
"
print_separator

# --- Step 3: Check GLIBC version ---
echo "Checking GLIBC version..."

python -c "
import subprocess
import sys

try:
    # Check GLIBC version
    result = subprocess.run(['ldd', '--version'], capture_output=True, text=True)
    glibc_info = result.stdout.split('\n')[0]
    print(f'GLIBC info: {glibc_info}')
    
    # Extract version number
    import re
    version_match = re.search(r'(\d+\.\d+)', glibc_info)
    if version_match:
        glibc_version = float(version_match.group(1))
        print(f'GLIBC version: {glibc_version}')
        
        if glibc_version >= 2.32:
            print('✅ GLIBC version is compatible with Flash Attention wheels.')
        else:
            print('⚠️  GLIBC version is older than 2.32. May need to compile Flash Attention from source.')
    else:
        print('❌ Could not parse GLIBC version.')
        
except Exception as e:
    print(f'❌ Error checking GLIBC: {e}')
"
print_separator

# --- Step 4: Run test for Flash Attention initialization ---
echo "Running Flash Attention initialization test..."

python -c "
try:
    import flash_attn
    print('✅ Flash Attention is installed.')
    print(f'Flash Attention version: {flash_attn.__version__}')
    
    # Try to actually use flash attention
    try:
        from flash_attn import flash_attn_func
        print('✅ Flash Attention functions are accessible.')
    except ImportError as e:
        print(f'⚠️  Flash Attention installed but functions not accessible: {e}')
        
except ImportError as e:
    print('❌ Flash Attention is not installed or has compatibility issues.')
    print(f'Error details: {e}')
    
    # Check if it's a GLIBC issue
    if 'GLIBC' in str(e):
        print('📝 This appears to be a GLIBC compatibility issue.')
        print('   Possible solutions:')
        print('   1. Install Flash Attention from source: pip uninstall flash-attn -y && MAX_JOBS=4 pip install flash-attn --no-build-isolation')
        print('   2. Try an older version: pip install flash-attn==2.5.0 --no-build-isolation')
        print('   3. Run the fix script: bash additional_packages/flash_attn_fix.sh')
"
print_separator

# --- Step 5: Run test for vLLM inference ---
echo "Running vLLM inference test..."

# Create a temporary python script for the vLLM test
cat << 'EOF' > vllm_test.py
from vllm import LLM, SamplingParams

# Some example prompts
prompts = [
    "Hello, my name is",
    "The capital of France is",
]

# Create a sampling parameters object
sampling_params = SamplingParams(temperature=0.7, top_p=0.95, max_tokens=20)

# Initialize the LLM with a small, generally available model
try:
    llm = LLM(model="facebook/opt-125m")
    outputs = llm.generate(prompts, sampling_params)

    print("✅ vLLM inference test successful.")
    # Print the outputs
    for output in outputs:
        prompt = output.prompt
        generated_text = output.outputs[0].text
        print(f"Prompt: \"{prompt}\"")
        print(f"Generated text: \"{generated_text}\"")
        print("---")
except Exception as e:
    print(f"❌ vLLM inference test failed with an error: {e}")

EOF

# Execute the vLLM test script
python vllm_test.py

# Clean up the temporary script
rm vllm_test.py

print_separator
echo "All tests complete."

# Deactivate the conda environment
conda deactivate
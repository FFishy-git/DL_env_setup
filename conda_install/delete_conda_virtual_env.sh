#!/bin/bash

# A script to safely select and delete a Conda virtual environment.

# --- Helper Function ---
# Function to display a separator line for better readability
print_separator() {
    echo "------------------------------------------------------------------"
}

# --- Main Script Logic ---

echo "Conda Environment Deletion Utility"
print_separator

# Check if conda is installed and available in the current shell
if ! command -v conda &> /dev/null; then
    echo "❌ Error: 'conda' command not found."
    echo "Please make sure Conda is installed and its 'bin' directory is in your PATH."
    exit 1
fi

echo "Searching for available Conda environments..."

# Get a clean list of conda environments, excluding the header and the 'base' environment.
# The awk command prints the first column (the name).
# The grep command excludes the 'base' environment to prevent accidental deletion.
ENV_LIST=($(conda env list | grep -v '^#' | awk '{print $1}' | grep -v '^base$'))

# Check if any deletable environments were found
if [ ${#ENV_LIST[@]} -eq 0 ]; then
    echo "No deletable Conda environments found (other than 'base')."
    exit 0
fi

echo "Please select the Conda environment you wish to delete:"

# PS3 is the prompt string for the select command
PS3="Enter the number of the environment (or 'q' to quit): "

select ENV_TO_DELETE in "${ENV_LIST[@]}"; do
    # Allow the user to quit by entering 'q' or 'Q'
    if [[ "$REPLY" == "q" || "$REPLY" == "Q" ]]; then
        echo "Quitting. No environments were deleted."
        exit 0
    fi

    # Check if the selection is valid
    if [ -n "$ENV_TO_DELETE" ]; then
        print_separator
        echo "You have selected to delete the Conda environment: '$ENV_TO_DELETE'"
        print_separator

        # Final, explicit confirmation before deleting
        read -p "Are you absolutely sure you want to permanently delete '$ENV_TO_DELETE'? This action cannot be undone. (y/N): " CONFIRMATION

        # Check the user's confirmation
        if [[ "$CONFIRMATION" == "y" || "$CONFIRMATION" == "Y" ]]; then
            echo "Deleting '$ENV_TO_DELETE'..."
            
            # The 'conda remove' command is the correct way to delete an environment.
            # '--name' specifies the environment by name.
            # '--all' removes all packages within the environment.
            # '-y' automatically confirms the action for conda's own prompt.
            conda remove --name "$ENV_TO_DELETE" --all -y

            # Check the exit code of the conda command to confirm success
            if [ $? -eq 0 ]; then
                echo "✅ Successfully deleted '$ENV_TO_DELETE'."
            else
                echo "❌ An error occurred while trying to delete '$ENV_TO_DELETE'."
                echo "Please check the output above for details from Conda."
            fi
        else
            echo "Deletion cancelled. '$ENV_TO_DELETE' was not deleted."
        fi
        break
    else
        echo "Invalid selection. Please choose a number from the list."
    fi
done

exit 0
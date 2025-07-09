# LLM Training/Inference Environment Setup 

A one-line setup command for yale cluster environment. 

- 🚀 Multi-platform Support: Can be used not only on Yale clusters but also on other linux platforms.
- 🔒 Secure Environment: All personal tokens and sensitive data remain local during the process.
- ⚡ All-in-One Command: Run `bash auto_setup.sh` to configure the entire environment instantly.

### Use for Yale Cluster
For Yale cluster users, run:
```bash
bash yale_cluster_install.sh
```
During execution, the script will prompt for:
- The name to create for your new conda virtual environment. 
- Desired Python version (recommended: 3.12).

You can skip if you prefer using an old environment. 
Optionally, you can enter personal tokens to log in to services such as WandB, Hugging Face, or GitHub. All data is processed locally, ensuring your information remains private.

This is an interactive bash command, and more details are available in the logging information when running this bash command. 

### Use for Other platform 

```bash 
bash conda_install/conda_env_create_activate.sh
bash ml_package_install.sh
```
Proceedures might not apply to all platforms. But it is easy to custom the code for your case. 

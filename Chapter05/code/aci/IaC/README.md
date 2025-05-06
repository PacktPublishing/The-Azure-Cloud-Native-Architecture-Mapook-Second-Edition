# Quick notes

- Make sure to have your own Azure subscription with owner permissions
- Make sure to download Visual Studio Code, Azure CLI and Terraform
- run az login
- Modify config.yaml to put your own subscription identifier and a unique storage account name.
- Use the provided container image or modify config.yaml accordingly if you built your own but I advise you not to do so (not relevant). I'll make sure the image remains in my DockerHub repo.
- Once the config is updated, run 'terraform init' followed by 'terraform apply --auto-approve'.
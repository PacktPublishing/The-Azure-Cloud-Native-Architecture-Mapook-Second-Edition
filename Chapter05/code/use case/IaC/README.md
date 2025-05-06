# Quick notes

- Make sure to have your own Azure subscription with owner permissions
- Make sure to download Visual Studio Code, Azure CLI and the PowerShell extension if you're not on Windows.
- run az login
- Modify deploy.ps1 to put your own service bus namespace which must be unique.
- Use the provided container image or modify config.yaml accordingly if you built your own but I advise you not to do so (not relevant). I'll make sure the image remains in my DockerHub repo.
- Once the config is updated, run 'terraform init' followed by 'terraform apply --auto-approve'.
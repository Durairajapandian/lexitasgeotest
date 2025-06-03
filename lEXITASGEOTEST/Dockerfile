# Use the official Azure Functions PowerShell base image
FROM mcr.microsoft.com/azure-functions/powershell:4

# Set the working directory inside the container
WORKDIR /home/site/wwwroot

# Copy all function app files from the current directory into the container
COPY . .

# Optional: Set environment variables (helps Azure detect the runtime)
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true
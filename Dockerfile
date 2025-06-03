# Use the official Azure Functions PowerShell runtime image
FROM mcr.microsoft.com/azure-functions/powershell:4

# Set environment variables expected by the Azure Functions host
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

# Copy all function code into the container
COPY . /home/site/wwwroot
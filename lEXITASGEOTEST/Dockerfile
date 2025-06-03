# Use the official Azure Functions PowerShell runtime image
FROM mcr.microsoft.com/azure-functions/powershell:4

# Set environment variables expected by the Azure Functions host
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

# Copy everything in the context to the Azure Functions root
COPY . /home/site/wwwroot
# Use Microsoft’s official PowerShell image
FROM mcr.microsoft.com/powershell:latest

# Set working directory inside the container
WORKDIR /app

# Copy the PowerShell script into the image
COPY ROS-Dev-RG-DLQ-Alert.ps1 .

# Optional: give execution permissions (not strictly required for PowerShell)
RUN chmod +x ROS-Dev-RG-DLQ-Alert.ps1

# Default command to run the script
CMD ["pwsh", "./ROS-Dev-RG-DLQ-Alert.ps1"]

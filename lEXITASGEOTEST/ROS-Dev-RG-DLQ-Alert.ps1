# Ensure the Az module is imported
Import-Module Az.Accounts
Import-Module Az.ServiceBus

# Define parameters
$queues = @(
    "sbq-ros-business-template-dev",
    "sbq-ros-document-local",
    "sbq-ros-document-process-dev",
    "sbq-ros-document-process-local",
    "sbq-ros-draftorder-dev",
    "sbq-ros-efax-dev",
    "sbq-ros-email-dev",
    "sbq-ros-export2excel-dev",
    "sbq-ros-filevinedto-dev",
    "sbq-ros-filevineevent-dev",
    "sbq-ros-filevineeventlog-dev",
    "sbq-ros-firmhierarchyaccess-dev",
    "sbq-ros-medicalprocessing-push-dev",
    "sbq-ros-processintegrationorders-dev",
    "sbq-ros-reassignamae-dev",
    "sbq-ros-serveautomation-dev"
)
$namespaceName = "sb-lxros-dev"
$resourceGroupName = "ROS-Dev-RG"
$subscriptionId = "0b251e88-da45-4dc7-8abb-8a961528eba7"

# JIRA settings
$jiraUrl = "https://lexitas.atlassian.net"
$jiraProjectKey = "ROS2"
$jiraUsername = "durai.pandian@lexitaslegal.com"
$jiraApiToken = "ATATT3xFfGF0B6kv80gU2Q2_PTs1zxdknOEvXs2rwOt4xMwu2UudX9cQrfhSB9mQ-mxtLazFdKlfAd4cENQsMRWUtKRwhcZhzal-jaEN9aD-6_bx7ehD8PXHo_9SdHZ-3_GmCdgAFVqgJ_k3spiOO0yKWWcInLpOTBq_opI0-BilhFKv7LFpUqo=B5992679"

# Ensure the directory for the count file exists
$countFilePath = "C:\temp\deadlettercounts"
if (-not (Test-Path $countFilePath)) {
    New-Item -ItemType Directory -Path $countFilePath -Force
}

# Function to get the dead-letter message count
function Get-DeadLetterMessageCount {
    param (
        $queueName
    )

    try {
        Write-Host "Attempting to retrieve Service Bus Queue details for $queueName..."
        $queueDetails = Get-AzServiceBusQueue -ResourceGroupName $resourceGroupName -NamespaceName $namespaceName -Name $queueName -SubscriptionId $subscriptionId
        if ($null -eq $queueDetails) {
            throw "Service Bus Queue details could not be retrieved. Please check the parameters and try again."
        }
        Write-Host "Service Bus Queue details retrieved successfully."
        Write-Host "Queue Details: $($queueDetails | Out-String)"

        if ($queueDetails.CountDetailDeadLetterMessageCount -ne $null) {
            return $queueDetails.CountDetailDeadLetterMessageCount
        } else {
            throw "DeadLetterMessageCount property is missing in the queue details."
        }
    } catch {
        Write-Error "An error occurred while retrieving the dead-letter message count for ${queueName}: $_"
        return $null
    }
}

# Function to create a JIRA ticket
function Create-JiraTicket {
    param (
        $queueName,
        $currentCount,
        $previousCount
    )

    $issueData = @{
        fields = @{
            project     = @{ key = $jiraProjectKey }
            summary     = "Dead Letter Message Count Increased for ${queueName}"
            description = "The CountDetailDeadLetterMessageCount for the Service Bus queue '${queueName}' has increased to ${currentCount}. Previous count was ${previousCount}."
            issuetype   = @{ name = "Task" }
        }
    } | ConvertTo-Json -Depth 3

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${jiraUsername}:${jiraApiToken}"))
    
    try {
        $response = Invoke-RestMethod -Uri "${jiraUrl}/rest/api/2/issue" -Method Post -Body $issueData -Headers @{ Authorization = "Basic $base64AuthInfo"; "Content-Type" = "application/json" }
        Write-Host "JIRA ticket created successfully: $($response.key)"
    } catch {
        Write-Error "Failed to create JIRA ticket: $_"
        
        # Detailed error message using Invoke-WebRequest
        try {
            $response = Invoke-WebRequest -Uri "${jiraUrl}/rest/api/2/issue" -Method Post -Body $issueData -Headers @{ Authorization = "Basic $base64AuthInfo"; "Content-Type" = "application/json" }
        } catch {
            Write-Error "Detailed error message: $_"
        }
    }
}

# Iterate through each queue
foreach ($queueName in $queues) {
    # File to store the previous count for each queue
    $countFile = "$countFilePath\$queueName.txt"

    # Get the current dead-letter message count
    $currentCount = Get-DeadLetterMessageCount -queueName $queueName

    if ($null -ne $currentCount) {
        Write-Host "Current Dead Letter Message Count for ${queueName}: $currentCount"

        # Read the previous count from file
        $previousCount = 0
        if (Test-Path $countFile) {
            $previousCount = [int](Get-Content $countFile)
        }

        Write-Host "Previous Dead Letter Message Count for ${queueName}: $previousCount"

        # Check if the current count is greater than the previous count
        if ($currentCount -gt $previousCount) {
            Write-Host "Dead Letter Message Count for ${queueName} has increased. Creating JIRA ticket..."

            # Create JIRA ticket
            Create-JiraTicket -queueName $queueName -currentCount $currentCount -previousCount $previousCount
        } else {
            Write-Host "Dead Letter Message Count for ${queueName} has not increased."
        }

        # Update the count file with the current count
        $currentCount | Out-File $countFile -Force
    } else {
        Write-Error "Failed to retrieve the current dead-letter message count for ${queueName}."
    }
}

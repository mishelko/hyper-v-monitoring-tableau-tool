# Define the list of Hyper-V hostnames
$vmHosts = @(
    "sit-vmhost",
    "sit-vmhost2",
    "sit-vmhost3",
    "sit-vmhost4",
    "sit-vmhost5",
    "sit-vmhost7",
    "sit-vmhost8",
    "sit-vmhost9"
)

# Define the local directory to store consolidated CSV files
$localCsvDir = "C:\Scripts\Combined"
if (!(Test-Path -Path $localCsvDir)) {
    New-Item -ItemType Directory -Path $localCsvDir -Force
}

# Initialize arrays to hold all data
$allVmMetrics = @()
$allHostMetrics = @()
$allDiskMetrics = @()

foreach ($vmHost in $vmHosts) {
    try {
        Write-Host "🔄 Processing $vmHost..."

        $remoteVmPath    = "\\$vmHost\Scripts\HyperV_VM_Usage.csv"
        $remoteHostPath  = "\\$vmHost\Scripts\Host_Usage.csv"
        $remoteDiskPath  = "\\$vmHost\Scripts\Disk_Usage.csv"

        # VM Metrics
        if (Test-Path $remoteVmPath) {
            $vmData = Import-Csv $remoteVmPath
            foreach ($row in $vmData) {
                $row | Add-Member -NotePropertyName "Host" -NotePropertyValue $vmHost -Force
                $allVmMetrics += $row
            }
        }

        # Host Metrics
        if (Test-Path $remoteHostPath) {
            $hostData = Import-Csv $remoteHostPath
            foreach ($row in $hostData) {
                $row | Add-Member -NotePropertyName "Host" -NotePropertyValue $vmHost -Force
                $allHostMetrics += $row
            }
        }

        # Disk Metrics
        if (Test-Path $remoteDiskPath) {
            $diskData = Import-Csv $remoteDiskPath
            foreach ($row in $diskData) {
                $row | Add-Member -NotePropertyName "Host" -NotePropertyValue $vmHost -Force
                $allDiskMetrics += $row
            }
        }

    } catch {
        Write-Warning "❌ Failed to process ${vmHost}: $_"
    }
}

# Export consolidated data
$allVmMetrics   | Export-Csv "$localCsvDir\All_HyperV_VM_Usage.csv" -NoTypeInformation
$allHostMetrics | Export-Csv "$localCsvDir\All_Host_Usage.csv" -NoTypeInformation
$allDiskMetrics | Export-Csv "$localCsvDir\All_Disk_Usage.csv" -NoTypeInformation

Write-Host "✅ Consolidation complete. Files saved to: $localCsvDir"

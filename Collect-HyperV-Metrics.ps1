# Define output directory
$OutputDir = "C:\Scripts"
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir
}

# Enable resource metering for all VMs
Get-VM | Enable-VMResourceMetering

# Collect VM metrics with vCPU count
$vmMetrics = Get-VM | Measure-VM | ForEach-Object {
    $vm = $_
    $vmConfig = Get-VM -Name $vm.VMName
    $vm | Select-Object `
        VMName,
        ComputerName,
        @{Name="vCPU_Count"; Expression={$vmConfig.ProcessorCount}},
        AverageProcessorUsage,
        AverageMemoryUsage,
        MaximumMemoryUsage,
        MinimumMemoryUsage,
        TotalDiskAllocation,
        AggregatedAverageNormalizedIOPS,
        AggregatedAverageLatency,
        AggregatedDiskDataRead,
        AggregatedDiskDataWritten,
        MeteringDuration
}

# Export VM metrics to CSV
$vmMetrics | Export-Csv -Path "$OutputDir\HyperV_VM_Usage.csv" -NoTypeInformation

# Collect host-level metrics
$hostName = $env:COMPUTERNAME
$cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
$availableMemory_MB = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue

# Get total & available memory
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$totalMemory_KB = $osInfo.TotalVisibleMemorySize
$totalMemory_GB = [math]::Round($totalMemory_KB / 1048576, 2)
$availableMemory_GB = [math]::Round($availableMemory_MB / 1024, 2)

# Get CPU physical core count and logical processor count
$cpuInfo = Get-CimInstance -ClassName Win32_Processor
$totalCores = ($cpuInfo | Measure-Object -Property NumberOfCores -Sum).Sum
$totalLogicalProcessors = ($cpuInfo | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

# Export host metrics to CSV
$hostMetrics = [PSCustomObject]@{
    HostName             = $hostName
    CPU_Usage            = [math]::Round($cpuUsage, 2)
    AvailableMemory_MB   = [math]::Round($availableMemory_MB, 2)
    AvailableMemory_GB   = $availableMemory_GB
    TotalMemory_GB       = $totalMemory_GB
    CPU_Cores            = $totalCores
    LogicalProcessors    = $totalLogicalProcessors
}
$hostMetrics | Export-Csv -Path "$OutputDir\Host_Usage.csv" -NoTypeInformation

# Collect disk metrics
$diskInfo = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | Select-Object `
    @{Name='DriveLetter';Expression={$_.DeviceID}},
    @{Name='FreeSpace_GB';Expression={[math]::Round($_.FreeSpace/1GB,2)}},
    @{Name='TotalSize_GB';Expression={[math]::Round($_.Size/1GB,2)}}

# Export disk metrics to CSV
$diskInfo | Export-Csv -Path "$OutputDir\Disk_Usage.csv" -NoTypeInformation

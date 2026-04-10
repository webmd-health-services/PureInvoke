
function Invoke-AdvApiQueryServiceConfig
{
    <#
    .SYNOPSIS
    Calls the Win32 API `QueryServiceConfig` function to retrieve a service's configuration.

    .DESCRIPTION
    The `Invoke-AdvApiQueryServiceConfig` function calls the Win32 API `QueryServiceConfig` function to retrieve a
    service's configuration. It returns an object with the properties that match the
    [QUERY_SERVICE_CONFIG](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw)
    structure:

    * ServiceType
    * StartType
    * ErrorControl
    * BinaryPathName
    * LoadOrderGroup
    * TagID
    * Dependencies
    * ServiceStartName
    * DisplayName

    Use the `Invoke-AdvApiOpenSCManager` function to open the Service Control Manager, then use
    `Invoke-AdvApiOpenService` to get a handle to the service whose configuration you want to get, passing the
    `QueryConfig` flag to `DesiredAccess`. Pass the service handle to `Invoke-AdvApiQueryServiceConfig` to get the
    service's configuration.

    .EXAMPLE
    Invoke-AdvApiQueryServiceConfig -ServiceHandle $handle

    Demonstrates how to use Invoke-AdvApiQueryServiceConfig to get the configuration for a service.
    #>
    [CmdletBinding()]
    param(
        # The handle to the service whose configuration to get. Use the `Invoke-AdvApiOpenSCManager` function to open
        # the Service Control Manager, then use `Invoke-AdvApiOpenService` to get a handle to the service.
        [Parameter(Mandatory)]
        [IntPtr] $ServiceHandle
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [UInt32] $bytesNeeded = 0

    $advApi = Get-AdvApi32
    $ok = $advApi::QueryServiceConfig($ServiceHandle, [IntPtr]::Zero, 0, [ref] $bytesNeeded)
    $lastError = [Marshal]::GetLastWin32Error()
    if (-not $ok -and $lastError -ne [PureInvoke_ErrorCode]::InsufficientBuffer)
    {
        $msg = "Failed to determine memory needed to read service configuration."
        Write-Win32Error -ErrorCode $lastError -Message $msg
        return
    }

    $ptrInfo = [Marshal]::AllocHGlobal($bytesNeeded)

    $ok = $advApi::QueryServiceConfig($ServiceHandle, $ptrInfo, $bytesNeeded, [ref] $bytesNeeded)
    $lastError = [Marshal]::GetLastWin32Error()
    if (-not $ok)
    {
        Write-Win32Error -ErrorCode $lastError -Message "Failed to query service configuration."
        return
    }

    $config = $advApi | New-PInvokeStruct -Name 'ServiceConfig'
    [Marshal]::PtrToStructure($ptrInfo, $config)
    [Marshal]::FreeHGlobal($ptrInfo)

    return [pscustomobject] @{
        ServiceType = [Enum]::ToObject([ServiceProcess.ServiceType], $config.ServiceType)
        StartType = [Enum]::ToObject([ServiceProcess.ServiceStartMode], $config.StartType)
        ErrorControl = [PureInvoke_ServiceErrorControl]$config.ErrorControl
        BinaryPathName = $config.BinaryPathName
        LoadOrderGroup = $config.LoadOrderGroup
        TagID = $config.TagId
        Dependencies = $config.Dependencies
        ServiceStartName = $config.ServiceStartName
        DisplayName = $config.DisplayName
    }
}

function Invoke-AdvApiQueryServiceConfig
{
    <#
    .SYNOPSIS
    Calls the `QueryServiceConfig` Windows API function to retrieve a service's configuration.

    .DESCRIPTION
    The `Invoke-AdvApiQueryServiceConfig` function calls the `QueryServiceConfig` Windows API function to retrieve a
    service's configuration. Pass a handle to the service to the `ServiceHandle` parameter. The function returns an
    `[pscustomobject]` with properties that correspond to the properties on the native
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
    `Invoke-AdvApiOpenService` to get a handle to the service whose configuration you want to get, passing `QueryConfig`
    as the desired access.

    .EXAMPLE
    Invoke-AdvApiQueryServiceConfig -ServiceHandle $handle

    Demonstrates how to use Invoke-AdvApiQueryServiceConfig to get the configuration for a service.
    #>
    [CmdletBinding()]
    param(
        # The handle to the service whose configuration to get. Use the `Invoke-AdvApiOpenSCManager` function to open
        # the Service Control Manager, then use `Invoke-AdvApiOpenService` with `QueryConfig` as the desired access to
        # get a handle to the service.
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

    try
    {
        [String[]]$dependencies = ConvertFrom-MultiString -Handle $config.Dependencies
        if ($null -eq $dependencies)
        {
            $dependencies = [String[]]::New(0)
        }
        return [pscustomobject] @{
            ServiceType = [Enum]::ToObject([ServiceProcess.ServiceType], $config.ServiceType)
            StartType = [Enum]::ToObject([ServiceProcess.ServiceStartMode], $config.StartType)
            ErrorControl = [PureInvoke_ServiceErrorControl]$config.ErrorControl
            BinaryPathName = $config.BinaryPathName
            LoadOrderGroup = $config.LoadOrderGroup
            TagID = $config.TagId
            Dependencies = $dependencies
            ServiceStartName = $config.ServiceStartName
            DisplayName = $config.DisplayName
        }
    }
    finally
    {
        [Marshal]::FreeHGlobal($ptrInfo)
    }
}

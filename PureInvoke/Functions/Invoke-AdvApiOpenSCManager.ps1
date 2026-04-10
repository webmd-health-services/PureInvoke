
function Invoke-AdvApiOpenSCManager
{
    <#
    .SYNOPSIS
    Calls the Win32 AdvApi32 API's `OpenSCManager` function to open a connection to the Windows Service Control Manager.

    .DESCRIPTION
    The `Invoke-AdvApiOpenSCManager` function calls the Win32 AdvApi32 API's `OpenSCManager` function to open a
    connection to the Windows Service Control Manager. By default, the local computer's Service Control Manager is
    opened. To connect to the manager on a different computer, pass that computer's name to the `MachineName` parameter.

    Use the `DesirecAccess` parameter to control the [access
    rights](https://learn.microsoft.com/en-us/windows/win32/services/service-security-and-access-rights) needed for the
    connection. By default, `Connect` is used. Values are:

    * Connect
    * CreateService
    * EnumerateService
    * Lock
    * QueryLockStatus
    * ModifyBootConfig
    * All
    * Read (EnumerateService and QueryLockStatus)
    * Write (CreateService and ModifyBootConfig)
    * Execute (Connect and Lock)

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/winsvc/nf-winsvc-openscmanagerw

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/services/service-security-and-access-rights

    .LINK
    Invoke-AdvApiCloseServiceHandle

    .EXAMPLE
    Invoke-AdvApiOpenSCManager

    Demonstrates how to connect to the local computer's Service Control Manager with lowest level of access.

    .EXAMPLE
    Invoke-AdvApiOpenSCManager -MachineName 'RemoteComputer'

    Demonstrates how to connect to the Service Control Manager on a remote computer by passing the computer's name to
    the `MachineName` parameter.

    .EXAMPLE
    Invoke-AdvApiOpenSCManager -DesiredAccess Write

    Demonstrates how to connect to the local computer's Service Control Manager in order to modify service configuration
    by passing `Wriate` as the desired access.

    .EXAMPLE
    Invoke-AdvApiOpenSCManager -DesiredAccess ([PureInvoke_ServiceControlManager_AccessRights]::Write -bor ([PureInvoke_ServiceControlManager_AccessRights]::Execute))


    Demonstrates how to combine access rights.
    #>
    [CmdletBinding()]
    [OutputType([IntPtr])]
    param (
        [String] $MachineName,

        [String] $DatabaseName,

        [PureInvoke_SCManagerAccessRights] $DesiredAccess
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $advApi32 = Get-AdvApi32

    if (-not $MachineName)
    {
        $MachineName = $null
    }

    $dbNameArg = [NullString]::Value
    if ($DatabaseName)
    {
        $dbNameArg = $DatabaseName
    }

    [UInt32] $accessMask = 0x0
    if ($DesiredAccess)
    {
        # PowerShell enums can only inherit from
        $accessMask = $DesiredAccess | Convert-IntToAccessMask
    }

    $handle = $advApi32::OpenSCManager($MachineName, $dbNameArg, $accessMask)
    $lastError = [Marshal]::GetLastWin32Error()
    if ($handle -eq [IntPtr]::Zero)
    {
        $databaseMsg = ''
        if ($DatabaseName)
        {
            $databaseMsg = " database ""${DatabaseName}"""
        }

        $computerMsg = ''
        if ($MachineName)
        {
            $computerMsg = " on computer ""${MachineName}"""
        }

        $accessMsg = ''
        if ($DesiredAccess)
        {
            $accessMsg = " with ${DesiredAccess} (0x$($accessMask.ToString("X"))) access"
        }
        $msg = "Failed to open service control manager${databaseMsg}${computerMsg}${accessMsg}."
        Write-Win32Error -ErrorCode $lastError -Message $msg
        return
    }

    return $handle
}
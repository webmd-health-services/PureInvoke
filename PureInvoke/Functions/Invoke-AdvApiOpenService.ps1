
function Invoke-AdvApiOpenService
{
    <#
    .SYNOPSIS
    Calls the win32 AdvApi32 API's `OpenService` function to open an existing service.

    .DESCRIPTION
    The `Invoke-AdvApiOpenService` function calls the win32 AdvApi32 API's `OpenService` function to open an existing
    service. Pass the handle to the service control manager to the `SCManagerHandle` parameter (use
    `Invoke-AdvApiOpenSCManager` to get a handle to the service control manager). Pass the name of the service to open
    to the `ServiceName` parameter. [Use the `DesiredAccess` parameter to specify what you want to do to the service
    once it is
    open](https://learn.microsoft.com/en-us/windows/win32/services/service-security-and-access-rights#access-rights-for-a-service).
    By default, `Read` access is used. Values are:

    * ChangeConfig
    * EnumerateDependents
    * Interrogate
    * PauseContinue
    * QueryConfig
    * QueryStatus
    * Start
    * Stop
    * UserDefinedControl
    * AllAccess
    * AccessSystemSecurity
    * Delete
    * ReadControl
    * WriteDac
    * WriteOwner
    * Read
    * Write
    * Execute

    .EXAMPLE
    Invoke-AdvApiOpenService -SCManagerHandle $scmHandle -ServiceName 'wuauserv'

    Demonstrates
    #>
    [CmdletBinding()]
    param (
        # Handle to the service control manager. Use `Invoke-AdvApiOpenSCManager` to get a handle to the service control
        # manager.
        [Parameter(Mandatory)]
        [IntPtr] $SCManagerHandle,

        # The name of the service to open. Accepts strings and service objects as from the pipeline.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $ServiceName,

        # [The desired access to the
        # service.](https://learn.microsoft.com/en-us/windows/win32/services/service-security-and-access-rights#access-rights-for-a-service)
        # By default, `Read` access is used. Values are:
        #
        # * ChangeConfig
        # * EnumerateDependents
        # * Interrogate
        # * PauseContinue
        # * QueryConfig
        # * QueryStatus
        # * Start
        # * Stop
        # * UserDefinedControl
        # * AllAccess
        # * AccessSystemSecurity
        # * Delete
        # * ReadControl
        # * WriteDac
        # * WriteOwner
        # * Read
        # * Write
        # * Execute
        [PureInvoke_ServiceAccessRights] $DesiredAccess
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $DesiredAccess)
        {
            $DesiredAccess = [PureInvoke_ServiceAccessRights]::Read
        }

        $svcHandle = (Get-AdvApi32)::OpenService($SCManagerHandle, $ServiceName, $DesiredAccess)
        $lastError = [Marshal]::GetLastWin32Error()
        if ($svcHandle -eq [IntPtr]::Zero)
        {
            $accessMsg = ''
            if ($DesiredAccess)
            {
                $accessMsg = " with ${DesiredAccess} (0x$($DesiredAccess.ToString("X").TrimStart('0'))) access"
            }

            $msg = "Failed to open service ${ServiceName}${accessMsg}."
            Write-Win32Error -ErrorCode $lastError -Message $msg
            return
        }

        return $svcHandle
    }
}
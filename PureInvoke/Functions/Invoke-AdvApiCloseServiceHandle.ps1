
function Invoke-AdvApiCloseServiceHandle
{
    <#
    .SYNOPSIS
    Calls the Win32 AdvApi32 API's `CloseServiceHandle` function to close a connection to the Winoows Service Control
    Manager.

    .DESCRIPTION
    The `Invoke-AdvApiCloseServiceHandle` function calls the Win32 AdvApi32 API's `CloseServiceHandle` function, to
    close a connection to the Winoows Service Control Manager. Pass the connection's handle to the `Handle` parameter.
    Use `Invoke-AdvApiOpenSCManager` to open a connection to the Service Control Manager. If the handle is null or
    zero, will write an error. Use `Test-PInvokeHandle` to check if a handle is valid or use `ErrorAction` to suppress
    the error.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/winsvc/nf-winsvc-closeservicehandle

    .LINK
    Invoke-AdvApiOpenSCManager

    .LINK
    Test-PInvokeHandle

    .EXAMPLE
    Invoke-AdvApiCloseServiceHandle -Handle $serviceHandle

    Demonstrates how to use `Invoke-AdvApiCloseServiceHandle` to close a handle to the Winoows Service Control Manager.
    #>
    [CmdletBinding()]
    param (
        # The handle to the Service Control Manager. Use `Invoke-AdvApiOpenSCManager` to open a connection to the
        # Service Control Manager.
        [Parameter(Mandatory, ValueFromPipeline)]
        [IntPtr] $Handle
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $result = (Get-AdvApi32)::CloseServiceHandle($Handle)
        $lastError = [Marshal]::GetLastWin32Error()
        if (-not $result)
        {
            Write-Win32Error -ErrorCode $lastError -Message "Failed to close service handle"
        }
    }
}
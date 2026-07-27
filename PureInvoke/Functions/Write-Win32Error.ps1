
function Write-Win32Error
{
    <#
    .SYNOPSIS
    Writes an error message for a Win32 error code.

    .DESCRIPTION
    The `Write-Win32Error` function writes an error mesage from a Windows error code. Pass the error code to
    `Write-Win32Error`. The function writes an error and sets the error's `Exception` to be a
    `[ComponentModel.Win32Exception]` object.

    Call `[Marshal]::GetLastWin32Error()` directly after calling a Windows functiton, otherwise you risk reporting an
    error caused by PowerShell itself. For example,

        $result = (Get-AdvApi32)::CloseServiceHandle($Handle)
        $lastError = [Marshal]::GetLastWin32Error()
        if (-not $result)
        {
            Write-Win32Error -ErrorCode $lastError -Message "Failed to close service handle"
        }

    Note how the error code is read directly after calling the Windows API, even before checking the result of the
    method call. This avoids `[Marshal]::GetLastWin32Error()` returning an error caused by PowerShell itself calling a
    Windows API.

    Pass a custom message to the `Message` parameter. The Windows error message is appended to any message that is
    passed.

    .EXAMPLE
    Write-Win32Error -ErrorCode $lastError

    Demonstrattes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int] $ErrorCode,

        [String] $Message
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($Message)
    {
        $Message = $Message.TrimEnd('.')
        $Message = "${Message}: "
    }

    $win32Ex = [Win32Exception]::New($ErrorCode)

    $period = '.'
    if ($win32ex.Message.EndsWith('.'))
    {
        $period = ''
    }

    $msg = "${Message}$($win32Ex.Message)${period} (0x$($win32Ex.ErrorCode.ToString('x'))/$($win32Ex.NativeErrorCode))"
    Write-Error -Exception $win32Ex -Message $msg -ErrorAction $ErrorActionPreference
}
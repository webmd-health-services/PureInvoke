
function Invoke-AdvApiLsaNtStatusToWinError
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaNtStatusToWinError` function to convert an NTSTATUS error code into a Win32
    error code.

    .DESCRIPTION
    The `Invoke-AdvApiLsaNtStatusToWinError` function calls the advapi32.dll library's `LsaNtStatusToWinError` function
    to convert an NTSTATUS error code into a Win32 error code. Pass the NTSTATUS code to the `Status` parameter. The
    equivalent Win32 error code is returned.

    .EXAMPLE
    Invoke-AdvApiLsaNtStatusToWinError -Status $ntstatus
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [UInt32] $Status
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return [PureInvoke.v3.AdvApi32]::LsaNtStatusToWinError($Status)
}
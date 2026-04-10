
function Invoke-AdvApiLsaFreeMemory
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaFreeMemory` function.

    .DESCRIPTION
    The `Invoke-AdvApiLsaFreeMemory` function calls the advapi32.dll library's `LsaFreeMemory` function. Pass the
    pointer whose memory to free to the `Handle` parameter. If the operation succeeds, the function returns `$true`,
    otherwise it returns `$false` and writes an error.

    .EXAMPLE
    Invoke-AdvApiLsaFreeMemory -Handle $rightsPtr

    Demonstrates how to call `Invoke-AdvApiLsaFreeMemory`.
    #>
    [CmdletBinding()]
    param(
        # The handle whose memory should be freed.
        [Parameter(Mandatory)]
        [IntPtr] $Handle
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $ntstatus = (Get-AdvApi32)::LsaFreeMemory($Handle)
    Assert-NTStatusSuccess -Status $ntstatus -Message 'Invoke-AdvApiLsaFreeMemory failed'
}
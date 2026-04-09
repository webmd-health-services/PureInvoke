
function Invoke-AdvApiLsaClose
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaClose` method to close an LSA policy handle.

    .DESCRIPTION
    The `Invoke-AdvApiLsaClose` function calls the advapi32.dll library's `LsaClose` method to close an LSA policy
    handle that was created with `Invoke-AdvApiLsaOpenPolicy`. Pass the policy handle to the `PolicyHandle` parameter.
    The function closes the policy and returns `$true` if the close succeeded. If the close fails, returns `$false` and
    writes an error.

    Closing a handle more than once may result in a process crash. After closing a handle, it is recommended to set it
    to `[IntPtr]::Zero` as a precaution. This function will ignore a policy handle set to `[IntPtr]::Zero`.

    .EXAMPLE
    Invoke-AdvApiLsaClose -PolicyHandle $handle

    Demonstrates how to call `Invoke-AdvApiLsaClose`.
    #>
    [CmdletBinding()]
    param(
        # The policy handle to close. Use `Invoke-AdvApiLsaOpenPolicy` to create policy handles.
        [Parameter(Mandatory)]
        [IntPtr] $PolicyHandle
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PolicyHandle -eq [IntPtr]::Zero)
    {
        return $true
    }

    $ntstatus = [PureInvoke.v3.AdvApi32]::LsaClose($PolicyHandle)
    Assert-NTStatusSuccess -Status $ntstatus -Message 'Invoke-AdvApiLsaClose failed'
}

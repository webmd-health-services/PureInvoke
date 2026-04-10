
function Invoke-AdvApiLsaAddAccountRights
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaAddAccountRights` function.

    .DESCRIPTION
    The `Invoke-AdvApiLsaAddAccountRights` function calls the advapi32.dll `LsaAddAccountRights` function. Pass a policy
    handle to the `PolicyHandle` parameter (use `Invoke-AdvApiLsaOpenPolicy` to create a policy handle), the security
    identifier for the account receiving rights to the `Sid` parameter, and a list of privileges/rights to add to the
    `Privilege` parameter. The account is granted the given rights.

    If the call succeeds, returns `$true`. Otherwise, returns `$false` and an error is written.

    .EXAMPLE
    Invoke-AdvApiLsaAddAccountRights -PolicyHandle $handle -Sid $sid -Privilege 'SeBatchLogonRight'

    Demonstrates how to call `Invoke-AdvApiLsaAddAccountRights`.
    #>
    [CmdletBinding()]
    param(
        # A handle to the policy. Use `Invoke-AdvApiLsaOpenPolicy` to get a handle. When opening the handle to add
        # account rights, you must use `LookupNames` and `CreateAccount` to the desired access.
        [Parameter(Mandatory)]
        [IntPtr] $PolicyHandle,

        # The account security identifier receiving the rights/privileges.
        [Parameter(Mandatory)]
        [SecurityIdentifier] $Sid,

        # The list of privileges to add.
        [Parameter(Mandatory)]
        [String[]] $Privilege
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sidPtr = ConvertTo-IntPtr -Sid $Sid

    [Object[]]$lsaPrivs = $Privilege | ConvertTo-LsaUnicodeString

    $advApi32 = Get-AdvApi32
    try
    {
        $ntstatus = $advApi32::LsaAddAccountRights($PolicyHandle, $sidPtr, $lsaPrivs, $lsaPrivs.Length)

        Assert-NTStatusSuccess -Status $ntstatus -Message 'LsaAddAccountRights failed'
    }
    finally
    {
        [Marshal]::FreeHGlobal($sidPtr)
    }
}

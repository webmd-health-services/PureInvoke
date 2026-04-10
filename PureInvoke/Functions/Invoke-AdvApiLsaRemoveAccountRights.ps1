
function Invoke-AdvApiLsaRemoveAccountRights
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaRemoveAccountRights` method which removes rights/privileges for an account.

    .DESCRIPTION
    The `Invoke-AdvApiLsaRemoveAccountRights` function calls the advapi32.dll library's `LsaRemoveAccountRights` method
    which removes rights/privileges for an account. Pass the LSA policy handle to the `PolicyHandle` parameter. Pass the
    security identifier for the account to the `Sid` parameter. To remove *all* of the account's rights, use the `All`
    switch. Otherwise, pass the specific rights to remove to the `Privilege` parameter. If the removal succeeds, the
    function returns `$true`, otherwise it returns `$false` and writes an error.

    In order to remove rights, the policy must be opened with the `LookupNames` access right.

    .EXAMPLE
    Invoke-AdvApiLsaRemoveAccountRights -PolicyHandle $handle -Sid $sid -All

    Demonstrates how to remove all of an account's privileges.

    .EXAMPLE
    Invoke-AdvApiLsaRemoveAccountRights -PolicyHandle $handle -Sid $sid -Privilege 'SeBatchLogonRight'

    Demonstrates how to remove a specific prilevege for an account.
    #>
    [CmdletBinding()]
    param(
        # A policy handle. Use `Invoke-AdvApiLsaOpenPolicy` to get a handle. When opening the handle to remove account
        # rights, you must request `LookupNames` access.
        [Parameter(Mandatory)]
        [IntPtr] $PolicyHandle,

        # The security identifier of the account whose rights/privileges to remove.
        [Parameter(Mandatory)]
        [SecurityIdentifier] $Sid,

        # If set, removes all of the account's privileges.
        [Parameter(Mandatory, ParameterSetName='All')]
        [switch] $All,

        # A list of the account's specific privileges to remove.
        [Parameter(Mandatory, ParameterSetName='Specific')]
        [String[]] $Privilege
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sidPtr = ConvertTo-IntPtr -Sid $Sid

    $advApi32 = Get-AdvApi32

    try
    {
        if ($All)
        {
            $ntstatus = $advApi32::LsaRemoveAccountRights($PolicyHandle, $sidPtr, $true, @(), 0)
        }
        else
        {
            [Object[]]$lsaPrivs = $Privilege | ConvertTo-LsaUnicodeString
            $ntstatus =
                $advApi32::LsaRemoveAccountRights($PolicyHandle, $sidPtr, $false, $lsaPrivs, $lsaPrivs.Length)
        }

        $winErr = Invoke-AdvApiLsaNtStatusToWinError -Status $ntstatus
        if ($winErr -eq [PureInvoke_ErrorCode]::FileNotFound)
        {
            return $true
        }

        Assert-NTStatusSuccess -Status $ntstatus -Message 'LsaRemoveAccountRights failed'
    }
    finally
    {
        [Marshal]::FreeHGlobal($sidPtr)
    }
}
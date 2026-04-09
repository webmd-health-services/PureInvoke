
function Invoke-AdvApiLsaEnumerateAccountRights
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll assembly's `LsaEnumerateAccountRights` function to get the list of an account's
    rights/privileges.

    .DESCRIPTION
    The `Invoke-AdvApiLsaEnumerateAccountRights` function calls the advapi32.dll assembly's `LsaEnumerateAccountRights`
    function to get the list of an account's rights/privileges. Pass a handle to the LSA policy to the `PolicyHandle`
    parameter (use `Invoke-AdvApiLsaOpenPolicy` to create a policy handle). Pass the security identifier for the account
    to the `Sid` parameter. The account's rights are returned. If the account has no rights, then nothing is returned.
    If getting the account's rights fails, nothing is returned and the function writes an error.

    In order to read an account's rights, the policy must be opened with the `LookupNames` access right.

    .EXAMPLE
    Invoke-AdvApiLsaEnumerateAccountRights -PolicyHandle $handle -Sid $sid

    Demonstrates how to call `Invoke-AdvApiLsaEnumerateAccountRights`
    #>
    [CmdletBinding()]
    param(
        # A policy handle. Use `Invoke-AdvApiLsaOpenPolicy` to get a handle. When opening the handle to get account
        # rights, you must request `LookupNames` access.
        [Parameter(Mandatory)]
        [IntPtr] $PolicyHandle,

        # The security identifier of the account whose rights/privileges to get.
        [Parameter(Mandatory)]
        [SecurityIdentifier] $Sid
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sidPtr = ConvertTo-IntPtr -Sid $Sid

    [IntPtr] $rightsPtr = [IntPtr]::Zero

    try
    {
        [UInt32] $rightsCount = 0
        $ntstatus = [PureInvoke.v3.AdvApi32]::LsaEnumerateAccountRights($PolicyHandle, $sidPtr, [ref] $rightsPtr,
                                                                     [ref] $rightsCount)

        $win32Err = Invoke-AdvApiLsaNtStatusToWinError -Status $ntstatus
        if ($win32Err -eq [PureInvoke_ErrorCode]::FileNotFound)
        {
            return
        }

        if (-not (Assert-NtStatusSuccess -Status $ntstatus -Message 'Invoke-AdvApiLsaEnumerateAccountRights failed'))
        {
            return
        }

        [PureInvoke.v3.LsaLookup.LSA_UNICODE_STRING[]] $lsaPrivs =
            [PureInvoke.v3.LsaLookup.LSA_UNICODE_STRING]::PtrToLsaUnicodeStrings($rightsPtr, $rightsCount)
        foreach ($lsaPriv in $lsaPrivs)
        {
            $lsaPrivLength = $lsaPriv.Length/[Text.UnicodeEncoding]::CharSize
            $cvt = [char[]]::New($lsaPrivLength)
            [Marshal]::Copy($lsaPriv.Buffer, $cvt, 0, $lsaPrivLength);
            [String]::New($cvt) | Write-Output
        }
    }
    finally
    {
        Invoke-AdvApiLsaFreeMemory -Handle $rightsPtr | Out-Null
        [Marshal]::FreeHGlobal($sidPtr)
    }
}
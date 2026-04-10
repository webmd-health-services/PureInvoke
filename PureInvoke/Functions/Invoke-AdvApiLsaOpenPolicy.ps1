
function Invoke-AdvApiLsaOpenPolicy
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaOpenPolicy` function to open a handle to a computer's LSA policy.

    .DESCRIPTION
    The `Invoke-AdvApiLsaOpenPolicy` function calls the advapi32.dll library's `LsaOpenPolicy` function to open a handle
    to a computer's LSA policy. Pass the desired access to the `DesiredAccess` parameter. The function returns a handle
    to the policy if opening succeeds or, if opening fails, returns nothing and writes an error.

    You can open the LSA policy on a different computer by passing the computer's name to the `ComputerName` parameter.

    .EXAMPLE
    Invoke-AdvApiLsaOpenPolicy -DesiredAccess LookupNames,CreateAccount

    Demonstrates how to open a policy handle that allows reading and setting privileges.
    #>
    [CmdletBinding()]
    param(
        # The desired access for the policy handle. See the documentation for the LSA function/method the policy will
        # be used with to discover what rights are needed.
        [Parameter(Mandatory)]
        [PureInvoke_LsaLookup_PolicyAccessRights[]] $DesiredAccess,

        # The optional computer name whose LSA policy to open. The default is the local computer.
        [String] $ComputerName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $ComputerName)
    {
        $ComputerName = [Environment]::MachineName
    }

    $advApi32 = Get-AdvApi32
    $lsaSystemName = $advApi32 | New-PInvokeStruct -Name 'LsaUnicodeString' -ArgumentList ($ComputerName)

    $objAttr = $advApi32 | New-PInvokeStruct -Name 'LsaObjectAttributes'
    $objAttr.Length = 0
    $objAttr.RootDirectory = [IntPtr]::Zero
    $objAttr.Attributes = 0
    $objAttr.SecurityDescriptor = [IntPtr]::Zero
    $objAttr.SecurityQualityOfService = [IntPtr]::Zero

    $policyHandle = [IntPtr]::Zero
    $accessMask = 0x0
    $DesiredAccess | ForEach-Object { $accessMask = $accessMask -bor $_ }

    $ntstatus = $advApi32::LsaOpenPolicy([ref] $lsaSystemName, [ref] $objAttr, $accessMask, [ref] $policyHandle)

    if (-not (Assert-NtStatusSuccess -Status $ntstatus -Message "Invoke-AdvApiLsaOpenPolicy failed"))
    {
        return
    }

    return $policyHandle
}
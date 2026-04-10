
function Invoke-AdvApiLookupPrivilegeValue
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LookupPrivilegeValue` function to lookup a privilege's local unique identifier.

    .DESCRIPTION
    The `Invoke-AdvApiLookupPrivilegeValue` function calls the advapi32.dll library's `LookupPrivilegeValue` function to
    lookup a privilege's LUID from its name. Pass the privilege's name to the `Name` parameter. If the privilege exists,
    its LUID is returned. Otherwise nothing is returned and an error is written.

    To run the lookup on a different computer, pass its name to the `ComputerName` parameter, which is passed to the
    `LookupPrivilegeValue` function's `SystemName` parameter, i.e. the lookup on the remote computer is done by
    `LookupPrivilegeValue`, not PowerShell.

    Privilege names *do not* include account rights, even though the names look similar. The following [known account
    rights](https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants) are not supported by
    `LookupPrivilegeValue`:

    * SeBatchLogonRight
    * SeDenyBatchLogonRight
    * SeDenyInteractiveLogonRight
    * SeDenyNetworkLogonRight
    * SeDenyRemoteInteractiveLogonRight
    * SeDenyServiceLogonRight
    * SeInteractiveLogonRight
    * SeNetworkLogonRight
    * SeRemoteInteractiveLogonRight
    * SeServiceLogonRight

    .EXAMPLE
    Invoke-AdvapiLookupPrivilegeName -Name SeDebugPrivilege

    Demonstrates how to call this function.
    #>
    [CmdletBinding()]
    param(
        # The privilege name whose value to lookup.
        [Parameter(Mandatory)]
        [String] $Name,

        # The computer name on which to lookup the value. This parameter is passed to the `LookupPrivilegeValue`
        # function's `SystemName` parameter, i.e. the lookup on the remote computer is done by `LookupPrivilegeValue`
        # not PowerShell.
        [String] $ComputerName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $advApi32 = Get-AdvApi32
    $luid = $advApi32 | New-PInvokeStruct -Name 'Luid'
    $result = $advApi32::LookupPrivilegeValue($ComputerName, $Name, [ref] $luid)
    $errCode = [Marshal]::GetLastWin32Error()

    if (-not $result -and -not (Assert-Win32Error -ErrorCode $errCode))
    {
        return
    }

    return [pscustomobject]@{
        LowPart = $luid.LowPart
        HighPart = $luid.HighPart
    }
}
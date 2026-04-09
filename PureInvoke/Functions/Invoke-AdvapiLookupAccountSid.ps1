
function Invoke-AdvApiLookupAccountSid
{
    <#
    .SYNOPSIS
    Calls the Advanced Windows 32 Base API (advapi32.dll) `LookupAccountSid` function.

    .DESCRIPTION
    The `Invoke-AdvApiLookupAccountSid` function calls the advapi32.dll API's `LookupAccountSid` function, which looks
    up a SID and returns its account name, domain name, and use. Pass the SID as a byte array to the `Sid` parameter and
    the system name to the `ComputerName` parameter, which are passed to `LookupAccountSid` as the `Sid` and
    `lpSystemName` arguments, respectively. The function returns an object with properties for each of the
    `LookupAccountSid` function's out parameters: `Name`, `ReferencedDomainName`, and `Use`.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupaccountsida

    .EXAMPLE
    Invoke-AdvApiLookupAccountSid -Sid $sid

    Demonstrates how to call this function by passing a sid to the `Sid` parameter.
    #>
    [CmdletBinding()]
    param(
        # The security identifier whose account to lookup.
        [Parameter(Mandatory)]
        [byte[]] $Sid,

        # The computer's name on which to lookup the SID. Defaults to the current computer. Passed to the
        # `LookupAccountSid` method's `SystemName` parameter.
        [String] $ComputerName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [StringBuilder] $name = [StringBuilder]::New()
    # cch = count of chars
    [UInt32] $cchName = $name.Capacity;

    [StringBuilder] $domainName = [StringBuilder]::New()
    [UInt32] $cchDomainName = $domainName.Capacity;

    [PureInvoke.v3.WinNT.SidNameUse] $sidNameUse = [PureInvoke.v3.WinNT.SidNameUse]::Unknown;

    $result = [PureInvoke.v3.AdvApi32]::LookupAccountSid($ComputerName, $sid, $name, [ref] $cchName, $domainName,
                                                      [ref] $cchDomainName, [ref] $sidNameUse)
    $errCode = [Marshal]::GetLastWin32Error()

    if (-not $result)
    {
        if ($errCode -eq [PureInvoke_ErrorCode]::InsufficientBuffer)
        {
            [void]$name.EnsureCapacity($cchName);
            [void]$domainName.EnsureCapacity($cchName);
            $result = [PureInvoke.v3.AdvApi32]::LookupAccountSid($ComputerName, $sid,  $name, [ref] $cchName, $domainName,
                                                       [ref] $cchDomainName, [ref] $sidNameUse)
            $errCode = [Marshal]::GetLastWin32Error()
        }

        if (-not $result -and -not (Assert-Win32Error -ErrorCode $errCode))
        {
            return
        }
    }

    return [pscustomobject]@{
        Name = $name.ToString();
        DomainName = $domainName.ToString();
        Use = $sidNameUse;
    }
}
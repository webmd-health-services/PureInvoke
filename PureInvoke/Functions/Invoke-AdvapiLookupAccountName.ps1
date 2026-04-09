
function Invoke-AdvApiLookupAccountName
{
    <#
    .SYNOPSIS
    Calls the Advanced Windows 32 Base API (advapi32.dll) `LookupAccountName` function.

    .DESCRIPTION
    The `Invoke-AdvApiLookupAccountName` function calls the advapi32.dll API's `LookupAccountName` function, which looks
    up an account name and returns its domain, SID, and use. Pass the account name to the `AccountName` parameter and
    the system name to the `ComputerName` parameter, which are passed to `LookupAccountName` as the `lpAccountName` and
    `lpSystemName` arguments, respectively. The function returns an object with properties for each of the
    `LookupAccountName` function's out parameters: `DomainName`, `Sid`, and `Use`.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupaccountnamea

    .EXAMPLE
    Invoke-AdvApiLookupAccountName -AccountName ([Environment]::UserName)

    Demonstrates how to call this function by passing a username to the `AccountName` parameter.
    #>
    [CmdletBinding()]
    param(
        # The account name to lookup.
        [Parameter(Mandatory)]
        [String] $AccountName,

        # The name of the system.
        [String] $ComputerName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [byte[]] $sid = [byte[]]::New(0);

    # cb = count of bytes
    [UInt32] $cbSid = 0;
    [StringBuilder] $sbDomainName = [StringBuilder]::New()
    # cch = count of chars
    [UInt32] $cchDomainName = $sbDomainName.Capacity;
    [PureInvoke.v3.WinNT.SidNameUse] $sidNameUse = [PureInvoke.v3.WinNT.SidNameUse]::Unknown;

    $result = [PureInvoke.v3.AdvApi32]::LookupAccountName($ComputerName, $AccountName, $sid, [ref] $cbSid, $sbDomainName,
                                                       [ref] $cchDomainName, [ref]$sidNameUse)
    $errCode = [Marshal]::GetLastWin32Error()

    if (-not $result)
    {
        if ($errCode -eq [PureInvoke_ErrorCode]::InsufficientBuffer -or `
            $errCode -eq [PureInvoke_ErrorCode]::InvalidFlags)
        {
            $sid = [byte[]]::New($cbSid);
            [void]$sbDomainName.EnsureCapacity([int]$cchDomainName);
            $result = [PureInvoke.v3.AdvApi32]::LookupAccountName($ComputerName, $AccountName, $sid, [ref] $cbSid,
                                                               $sbDomainName, [ref] $cchDomainName, [ref] $sidNameUse)
            $errCode = [Marshal]::GetLastWin32Error()
        }

        if (-not $result -and -not (Assert-Win32Error -ErrorCode $errCode))
        {
            return
        }
    }

    return [pscustomobject]@{
        DomainName = $sbDomainName.ToString();
        Sid = $sid
        Use = $sidNameUse
    }
}

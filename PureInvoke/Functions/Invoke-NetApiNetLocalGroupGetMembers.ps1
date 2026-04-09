
function Invoke-NetApiNetLocalGroupGetMembers
{
    <#
    .SYNOPSIS
    Calls the Win32 netapi32.dll library's `NetLocalGroupGetMembers` method, which gets the members of a local group.

    .DESCRIPTION
    The `Invoke-NetApiNetLocalGroupGetMembers` calls the Win32 netapi32.dll library's `NetLocalGroupGetMembers` method,
    which gets the members of a local group. Pass the name of the local group to the `LocalGroupName` parameter. The
    function will return an object with `SidPtr`, `SidUsage`, and `DomainAndName` properties.

    You can control what information to return with the `Level` parameter, which must be a value between 0 and 3. (The
    default is `2`.) Level 0 will return objects with just `SidPtr` properties. Level 1 will return objects with
    `SidPtr`, `SidUsage`, and `Name` properties. Level 2 (the default) will return objects with `SidPtr`, `SidUsage`,
    and `DomainAndName` properties. Level 3 will return object with just `DomainAndName` properties.

    All `SidPtr` properties are `IntPtr` instances that point to security identifier bytes. To convert the SID pointers
    to actual security identifiers, `[Security.Principal.SecurityIdentifier]::New($_.SidPtr)`.

    The `Name` property is just the sAMAccountName of the principal with no domain or computer information.

    .EXAMPLE
    Invoke-NetApiNetLocalGroupGetMembers -LocalGroupName 'Administrators'

    Demonstrates the simplest way to call this function to get a pointer to the SID, SID usage, and domain and username
    information about all the members of a group. In this example, all the members of the administrators group will be
    returned.

    .EXAMPLE
    Invoke-NetApiNetLocalGroupGetMembers -LocalGroupName 'Administrators' -Level 1

    Demonstrates how to customzie the object and object properties returned by using the `Level` parameter.
    #>
    [CmdletBinding()]
    param(
        [String] $ComputerName,

        [Parameter(Mandatory)]
        [String] $LocalGroupName,

        [ValidateRange(0,3)]
        [int] $Level = 2
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function New-InfoObject
    {
        switch ($Level)
        {
            0
            {
                return [PureInvoke.v3.Lmaccess.LOCALGROUP_MEMBERS_INFO_0]::New()
            }

            1
            {
                return [PureInvoke.v3.Lmaccess.LOCALGROUP_MEMBERS_INFO_1]::New()
            }

            2
            {
                return [PureInvoke.v3.Lmaccess.LOCALGROUP_MEMBERS_INFO_2]::New()
            }

            3
            {
                return [PureInvoke.v3.Lmaccess.LOCALGROUP_MEMBERS_INFO_3]::New()
            }
        }
    }

    [int] $entriesRead = 0
    [int] $totalEntries = 0
    [IntPtr] $resume  = [IntPtr]::Zero
    [IntPtr] $buffer = [IntPtr]::Zero

    do
    {
        $status = [PureInvoke.v3.NetApi32]::NetLocalGroupGetMembers($ComputerName,
                                                                 $LocalGroupName,
                                                                 $Level,
                                                                 [ref] $buffer,
                                                                 -1,
                                                                 [ref] $entriesRead,
                                                                 [ref] $totalEntries,
                                                                 [ref] $resume)
        if ($status -ne [PureInvoke_ErrorCode]::NERR_Success)
        {
            $msg = "Failed getting members of group ""${LocalGroupName}"""
            Assert-Win32Error -ErrorCode $status -Message $msg | Out-Null
            return
        }

        if ($entriesRead -gt 0)
        {
            [IntPtr] $itemAddr = $buffer
            for($i = 0; $i -lt $entriesRead; $i++)
            {
                $member = New-InfoObject
                [Marshal]::PtrToSTructure($itemAddr, [Type]$member.GetType()) |
                    Write-Output
                $itemAddr = [IntPtr]::New($itemAddr.ToInt64() + [Int64][Marshal]::SizeOf($member))
            }
            $status = [PureInvoke.v3.NetApi32]::NetApiBufferFree($buffer)
            Assert-Win32Error -ErrorCode $status | Out-Null
        }
    }
    while ($resume -ne [IntPtr]::Zero)
}
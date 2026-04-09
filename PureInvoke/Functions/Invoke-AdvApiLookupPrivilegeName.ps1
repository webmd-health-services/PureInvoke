
function Invoke-AdvApiLookupPrivilegeName
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LookupPrivilegeName` function to lookup a privilege name from its local unique
    identifier.

    .DESCRIPTION
    The `Invoke-AdvApiLookupPrivilegeName` function calls the advapi32.dll library's `LookupPrivilegeName` function to
    lookup a privilege name from its local unique identifier (i.e. LUID). Pass the privilege's LUID to the `LUID`
    parameter. If the privilege exists, its name is returned. Otherwise nothing is returned and an error is written.

    To run the lookup on a different computer, pass its name to the `ComputerName` parameter, which is passed to the
    `LookupPrivilegeName` function's `SystemName` parameter, i.e. the lookup on the remote computer is done by
    `LookupPrivilegeName`, not PowerShell.

    .EXAMPLE
    Invoke-AdvapiLookupPrivilegeName -LuidLowPart $luid.LowPart -LuidHighPart $luid.HighPart

    Demonstrates how to call this function.
    #>
    [CmdletBinding()]
    param(
        # The low part of the LUID of the priveilege to lookup.
        [Parameter(Mandatory)]
        [UInt32] $LuidLowPart,

        # The high part of the LUID of the privilege to lookup.
        [Parameter(Mandatory)]
        [int] $LuidHighPart,

        # The computer name on which to lookup the value. This parameter is passed to the `LookupPrivilegeValue`
        # function's `SystemName` parameter, i.e. the lookup on the remote computer is done by `LookupPrivilegeValue`
        # not PowerShell.
        [String] $ComputerName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sbName = [StringBuilder]::New(1)
    $nameLength = $sbName.Capacity

    $luid = [PureInvoke.v3.WinNT.LUID]::new()
    $luid.LowPart = $LuidLowPart
    $luid.HighPart = $LuidHighPart
    $ptrLuid = ConvertTo-IntPtr -LUID $LUID

    try
    {
        $result = [PureInvoke.v3.AdvApi32]::LookupPrivilegeName($ComputerName, $ptrLuid, $sbName, [ref] $nameLength)
        $errCode = [Marshal]::GetLastWin32Error()

        if (-not $result)
        {
            if ($errCode -eq [PureInvoke_ErrorCode]::InsufficientBuffer)
            {
                [void]$sbName.EnsureCapacity($nameLength)
                $result = [PureInvoke.v3.AdvApi32]::LookupPrivilegeName($ComputerName, $ptrLuid, $sbName, [ref] $nameLength)
                $errCode = [Marshal]::GetLastWin32Error()
            }

            if (-not $result -and -not (Assert-Win32Error -ErrorCode $errCode))
            {
                return
            }
        }

        return $sbName.ToString()
    }
    finally
    {
        [Marshal]::FreeHGlobal($ptrLuid)
    }
}
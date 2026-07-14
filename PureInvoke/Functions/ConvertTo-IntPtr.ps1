
function ConvertTo-IntPtr
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='SecurityIdentifier')]
        [SecurityIdentifier] $Sid,

        [Parameter(Mandatory, ParameterSetName='LUID')]
        [Object] $LUID
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($Sid)
    {
        $sidBytes = [byte[]]::New($Sid.BinaryLength)
        $sid.GetBinaryForm($sidBytes, 0);
        $sidPtr = [Marshal]::AllocHGlobal($sidBytes.Length)
        [Marshal]::Copy($sidBytes, 0, $sidPtr, $sidBytes.Length)
        return $sidPtr
    }

    if ($LUID)
    {
        $size = [Marshal]::SizeOf($LUID)
        $luidPtr = [Marshal]::AllocHGlobal($size)

        $lowBytes = [BitConverter]::GetBytes($LUID.LowPart)
        [Marshal]::Copy($lowBytes, 0, $luidPtr, $lowBytes.Length)

        $highBytes = [BitConverter]::GetBytes($LUID.HighPart)
        [Marshal]::Copy($highBytes, 0, [IntPtr]::Add($luidPtr, $lowBytes.Length), $highBytes.Length)

        return $luidPtr
    }
}

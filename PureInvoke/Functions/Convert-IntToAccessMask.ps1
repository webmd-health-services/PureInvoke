
function Convert-IntToAccessMask
{
    [CmdletBinding()]
    [OutputType([UInt32])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [int] $InputObject
    )

    process
    {
        [BitConverter]::ToUInt32([BitConverter]::GetBytes($InputObject), 0) | Write-Output
    }
}
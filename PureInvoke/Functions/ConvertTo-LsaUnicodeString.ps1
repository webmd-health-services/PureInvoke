
function ConvertTo-LsaUnicodeString
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        [PureInvoke.v3.LsaLookup.LSA_UNICODE_STRING]::New($InputObject) | Write-Output
    }
}
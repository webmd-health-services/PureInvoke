
function ConvertTo-LsaUnicodeString
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $advApi32 = Get-AdvApi32
    }

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        New-PInvokeStruct -InputObject $advApi32 -Name 'LsaUnicodeString' -ArgumentList ($InputObject) | Write-Output
    }
}
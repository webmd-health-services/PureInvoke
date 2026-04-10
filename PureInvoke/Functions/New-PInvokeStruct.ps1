
function New-PInvokeStruct
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Type] $InputObject,

        [Parameter(Mandatory)]
        [string] $Name,

        [Object[]] $ArgumentList
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $structType = Get-PInvokeStructType -InputObject $InputObject -Name $Name
        if (-not $structType)
        {
            return
        }

        if ($ArgumentList)
        {
            return $structType::New($ArgumentList)
        }

        return $structType::New()
    }
}

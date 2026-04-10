
function Get-PInvokeStructType
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $InputObject,

        [Parameter(Mandatory)]
        [String] $Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $structType = $InputObject.DeclaredNestedTypes | Where-Object 'Name' -EQ $Name
        if (-not $structType)
        {
            $msg = "Failed to find nested struct ""${Name}"" in $($InputObject.FullName)."
            Write-Error -Message $msg -ErrorAction Stop
            return
        }
        return $structType
    }
}
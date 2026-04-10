
function ConvertFrom-MultiString
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [IntPtr] $Handle
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Test-PInvokeHandle -Handle $Handle))
    {
        return
    }

    $pString = $Handle
    while ($true)
    {
        $string = [Marshal]::PtrToStringUni($pString)
        if ([String]::IsNullOrEmpty($string))
        {
            break
        }

        $string | Write-Output
        $pString = [IntPtr]::Add($pString, ($string.Length * 2) + 2)
    }
}
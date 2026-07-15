
function Test-PInvokeHandle
{
    <#
    .SYNOPSIS
    Tests if a handle is not null or zero.

    .DESCRIPTION
    The `Test-PInvokeHandle` function tests if a handle is not null or zero. It does not check if it can actually be
    used. Pass the handle to the `Handle` parameter or pipe the handle to `Test-PInvokeHandle`. Returns `$true` if the
    handle is not null and not zero, `$false` otherwise.

    .EXAMPLE
    Test-PInvokeHandle -Handle $handle

    Demonstrates testing a handle by passing it to the `Handle` parameter.

    .EXAMPLE
    $handle | Test-PInvokeHandle

    Demonstrates that you can pipe handles to `Test-PInvokeHandle`.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [IntPtr] $Handle
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        return ($null -ne $Handle -and $Handle -ne [IntPtr]::Zero)
    }
}
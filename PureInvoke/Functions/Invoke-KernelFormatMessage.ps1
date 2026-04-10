
function Invoke-KernelFormatMessage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int] $ErrorCode
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    # Define the FORMAT_MESSAGE_FROM_SYSTEM flag
    $FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000

    # Create a buffer to hold the formatted message
    $bufferSize = 1024
    $buffer = New-Object System.Text.StringBuilder($bufferSize)

    # Call the FormatMessage function from the Windows API
    $result = (Get-Kernel32)::FormatMessage(
        $FORMAT_MESSAGE_FROM_SYSTEM,
        [IntPtr]::Zero,
        $ErrorCode,
        0,
        $buffer,
        $bufferSize,
        [IntPtr]::Zero
    )

    if ($result -ne 0) {
        return $buffer.ToString().Trim()
    } else {
        throw "Failed to format message for error code: $ErrorCode"
    }
}

function Invoke-KernelGetNumaHighestNodeNumber
{
    <#
    .SYNOPSIS
    Calls the Windows API `GetNumaHighestNodeNumber` function.

    .DESCRIPTION
    The `Invoke-KernelGetNumaHighestNodeNumber` function calls the Windows API
    [`GetNumaHighestNodeNumber`](https://learn.microsoft.com/en-us/windows/win32/api/systemtopologyapi/nf-systemtopologyapi-getnumahighestnodenumber)
    function from the kernel32.dll library. According to [Allocating Memory from a NUMA
    Node](https://learn.microsoft.com/en-us/windows/win32/memory/allocating-memory-from-a-numa-node) sample code, a
    value of 0 means NUMA is not enabled.

    ```c++
    ULONG HighestNodeNumber;

    // ...snip...
    if (!GetNumaHighestNodeNumber (&HighestNodeNumber))
    {
        _tprintf (_T("GetNumaHighestNodeNumber failed: %d\n"), GetLastError());
        goto Exit;
    }

    if (HighestNodeNumber == 0)
    {
        _putts (_T("Not a NUMA system - exiting"));
        goto Exit;
    }
    ```

    .EXAMPLE
    Invoke-KernelGetNumaHighestNodeNumber

    Demonstrates how to call `Invoke-KernelGetNumaHighestNodeNumber`.
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $kernel32 = Get-Kernel32

    [Uint32] $result = 0
    $result = $kernel32::GetNumaHighestNodeNumber([ref]$result)
    $lastError = [Marshal]::GetLastWin32Error()
    if (-not $result)
    {
        Write-Win32Error -ErrorCode $lastError -Message "Failed to get NUMA highest node number."
        return
    }
    return $result
}
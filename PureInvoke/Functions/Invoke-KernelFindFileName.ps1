
function Invoke-KernelFindFileName
{
    <#
    .SYNOPSIS
    Calls the Win32 `FindFirstFileNameW` and `FindNextFileNameW` functions to get the hardlinks to a file.

    .DESCRIPTION
    The `Invoke-KernelFindFileName` function finds all the hardlinks to a file. It calls the Win32 `FindFirstFileNameW`
    and `FindNextFileNameW` functions to get the paths. It returns the path to each hardlink, which includes the path
    to the file itself. The paths are returned *without* drive qualifiers at the beginning. Since hardlinks can't cross
    physical file systems, their drives will be the same as the source path.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findfirstfilenamew

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findnextfilenamew

    .EXAMPLE
    Invoke-KernelFindFileName -Path 'C:\link.txt'

    Demonstrates how to get the hardlinks to a file by passing its path to the `Invoke-KernelFindFileName` function's
    `Path` parameter.
    #>
    [CmdletBinding()]
    param(
        # The path to the file.
        [Parameter(Mandatory)]
        [String] $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [PureInvoke_ErrorCode] $errCode = [PureInvoke_ErrorCode]::Ok

    # Loop over and collect all hard links as their full paths.
    [IntPtr]$findHandle = [IntPtr]::Zero

    [StringBuilder] $sbLinkName = [Text.StringBuilder]::New()
    [UInt32] $cchLinkName = $sbLinkName.Capacity
    $findHandle = [PureInvoke.v3.Kernel32]::FindFirstFileNameW($Path, 0, [ref]$cchLinkName, $sbLinkName)
    $errCode = [Marshal]::GetLastWin32Error()
    Write-Debug "[Kernel32]::FindFirstFileNameW(""${Path}"", 0, ${cchLinkName}, ""${sbLinkName}"")  return ${findHandle}  GetLastError() ${errCode}"
    if ($script:invalidHandle -eq $findHandle)
    {
        if ($errCode -eq [PureInvoke_ErrorCode]::MoreData)
        {
            [void]$sbLinkName.EnsureCapacity($cchLinkName)
            $findHandle = [PureInvoke.v3.Kernel32]::FindFirstFileNameW($Path, 0, [ref]$cchLinkName, $sbLinkName)
            $errCode = [Marshal]::GetLastWin32Error()
            Write-Debug "[Kernel32]::FindFirstFileNameW(""${Path}"", 0, ${cchLinkName}, ""${sbLinkName}""))  return ${findHandle}  GetLastError() ${errCode}"
            if ($script:invalidHandle -eq $findHandle)
            {
                Write-Win32Error -ErrorCode $errCode
                return
            }
        }
        else
        {
            Write-Win32Error -ErrorCode $errCode
            return
        }
    }

    $linkName = $sbLinkName.ToString()
    if (-not $linkName)
    {
        Write-Win32Error -ErrorCode $errCode
        return
    }

    $linkName | Write-Output

    try
    {
        do
        {
            [void]$sbLinkName.Clear()

            $result = [PureInvoke.v3.Kernel32]::FindNextFileNameW($findHandle, [ref]$cchLinkName, $sbLinkName)
            $errCode = [Marshal]::GetLastWin32Error()
            Write-Debug "[Kernel32]::FindNextFileNameW(${findHandle}, ${cchLinkName}, ""${sbLinkName}""))  return ${result}  GetLastError() ${errCode}"
            if (-not $result -and $errCode -eq [PureInvoke_ErrorCode]::MoreData)
            {
                [void]$sbLinkName.EnsureCapacity($cchLinkName)
                $result = [PureInvoke.v3.Kernel32]::FindNextFileNameW($findHandle, [ref]$cchLinkName, $sbLinkName)
                $errCode = [Marshal]::GetLastWin32Error()
                Write-Debug "[Kernel32]::FindNextFileNameW(${findHandle}, ${cchLinkName}, ""${sbLinkName}""))  return ${result}  GetLastError() ${errCode}"
            }

            if ($result)
            {
                $linkName = $sbLinkName.ToString()
                if (-not $linkName)
                {
                    Write-Win32Error -ErrorCode $errCode
                    return
                }

                $linkName | Write-Output
                continue
            }

            if ($errCode -eq [PureInvoke_ErrorCode]::HandleEof)
            {
                return
            }

            if($errCode -eq [PureInvoke_ErrorCode]::InvalidHandle)
            {
                $msg = 'No matching files found.'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }

            Write-Win32Error -ErrorCode $errCode
            return
        }
        while ($true)
    }
    finally
    {
        [void][PureInvoke.v3.Kernel32]::FindClose($findHandle);
    }
}

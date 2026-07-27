
function Get-Kernel32
{
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $kernel32 = @"
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool FindClose(IntPtr hFindFile);

        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern IntPtr FindFirstFileNameW(string lpFileName, uint dwFlags, ref uint stringLength,
            StringBuilder linkName);

        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern bool FindNextFileNameW(IntPtr hFindStream, ref uint stringLength, StringBuilder linkName);

        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern bool GetVolumePathName(string lpszFileName, [Out] StringBuilder lpszVolumePathName,
            uint cchBufferLength);

        [DllImport("kernel32.dll")]
        public static extern IntPtr LocalFree(IntPtr hMem);

        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool GetNumaHighestNodeNumber(out uint highestNodeNumber);
"@

    return Add-PInvokeType -DllName 'Kernel32' -Definition $kernel32
}
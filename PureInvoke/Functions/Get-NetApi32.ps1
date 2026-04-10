
function Get-NetApi32
{
    [CmdletBinding()]
    param()

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $netapi = @"
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct LocalGroupMembersInfo0
        {
            public IntPtr SidPtr;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct LocalGroupMembersInfo1
        {
            public IntPtr SidPtr;
            public int SidUsage;
            public string Name;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct LocalGroupMembersInfo2
        {
            public IntPtr SidPtr;
            public int SidUsage;
            public string DomainAndName;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct LocalGroupMembersInfo3
        {
            public string DomainAndName;
        }

        [DllImport("netapi32.dll", SetLastError=true)]
        public static extern int NetApiBufferFree(IntPtr Buffer);

        [DllImport("netapi32.dll", CharSet=CharSet.Unicode)]
        public static extern int NetLocalGroupGetMembers(
            [MarshalAs(UnmanagedType.LPWStr)]
            string servername,
            [MarshalAs(UnmanagedType.LPWStr)]
            string localgroupname,
            int level,
            out IntPtr bufptr,
            int prefmaxlen,
            out int entriesread,
            out int totalentries,
            ref IntPtr resumehandle);
"@

    return Add-PInvokeType -DllName 'NetApi32' -Definition $netapi
}
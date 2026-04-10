
function Get-AdvApi32
{
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $advApi = @"
        public struct Luid
        {
            public uint LowPart;
            public int HighPart;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct LsaUnicodeString
        {
            public LsaUnicodeString(string inputString)
            {
                if (inputString == null)
                {
                    Buffer = IntPtr.Zero;
                    Length = 0;
                    MaximumLength = 0;
                }
                else
                {
                    Buffer = Marshal.StringToHGlobalUni(inputString);
                    Length = (ushort)(inputString.Length * 2);
                    MaximumLength = (ushort)((inputString.Length + 1) * 2);
                }
            }

            public ushort Length;
            public ushort MaximumLength;
            public IntPtr Buffer;

            public static LsaUnicodeString[] PtrToLsaUnicodeStrings(IntPtr ptr, uint length)
            {
                var lsaStrings = new List<LsaUnicodeString>((int)length);

                var myLsaus = new LsaUnicodeString();
                for (ulong i = 0; i < length; i++)
                {
                    var itemAddr = new IntPtr(ptr.ToInt64() + (long)(i * (ulong)Marshal.SizeOf(myLsaus)));
                    myLsaus = Marshal.PtrToStructure<LsaUnicodeString>(itemAddr);
                    lsaStrings.Add(myLsaus);
                }
                return lsaStrings.ToArray();
            }
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct LsaObjectAttributes
        {
            public uint Length;
            public IntPtr RootDirectory;
            public LsaUnicodeString ObjectName;
            public uint Attributes;
            public IntPtr SecurityDescriptor;
            public IntPtr SecurityQualityOfService;
        }

        [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern bool LookupAccountName(
            string lpSystemName,
            string lpAccountName,
            [MarshalAs(UnmanagedType.LPArray)] byte[] Sid,
            ref uint cbSid,
            StringBuilder referencedDomainName,
            ref uint cchReferencedDomainName,
            out int peUse
        );

        [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern bool LookupAccountSid(
            string lpSystemName,
            [MarshalAs(UnmanagedType.LPArray)] byte[] Sid,
            StringBuilder lpName,
            ref uint cchName,
            StringBuilder referencedDomainName,
            ref uint cchReferencedDomainName,
            out int peUse
        );

        [DllImport("advapi32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool LookupPrivilegeName(
            string lpSystemName,
            IntPtr lpLuid,
            StringBuilder lpName,
            ref uint cbName
        );

        [DllImport("advapi32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, ref Luid lpLuid);

        [DllImport("advapi32.dll", CharSet=CharSet.Unicode)]
        public static extern uint LsaAddAccountRights(
            IntPtr policyHandle,
            IntPtr accountSid,
            LsaUnicodeString[] userRights,
            uint countOfRights);

        [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern uint LsaClose(IntPtr policyHandle);

        [DllImport("advapi32.dll", SetLastError=true)]
        public static extern uint LsaEnumerateAccountRights(IntPtr policyHandle,
            IntPtr accountSid,
            out IntPtr userRights,
            out uint countOfRights
        );

        [DllImport("advapi32.dll", SetLastError=true)]
        public static extern uint LsaFreeMemory(IntPtr pBuffer);

        [DllImport("advapi32.dll")]
        public static extern int LsaNtStatusToWinError(uint status);

        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
        public static extern uint LsaOpenPolicy(ref LsaUnicodeString systemName,
            ref LsaObjectAttributes objectAttributes, uint desiredAccess, out IntPtr policyHandle);

        [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
        public static extern uint LsaRemoveAccountRights(
            IntPtr policyHandle,
            IntPtr accountSid,
            [MarshalAs(UnmanagedType.U1)]
            bool AllRights,
            LsaUnicodeString[] userRights,
            uint countOfRights);
"@

    return Add-PInvokeType -DllName 'AdvApi32' -Definition $advApi
}
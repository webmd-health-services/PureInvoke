
using System;
using System.Runtime.InteropServices;

namespace PureInvoke.v3
{
	public static class NetApi32
	{
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

	}
}
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace PureInvoke.v3
{
	public static class Kernel32
	{
		[DllImport("kernel32.dll", SetLastError=true)]
		public static extern bool FindClose(IntPtr hFindFile);

		[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
		public static extern IntPtr FindFirstFileNameW(string lpFileName, uint dwFlags, ref uint StringLength, StringBuilder LinkName);

		[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
		public static extern bool FindNextFileNameW(IntPtr hFindStream, ref uint StringLength, StringBuilder LinkName);

		[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
		public static extern bool GetVolumePathName(string lpszFileName, [Out] StringBuilder lpszVolumePathName, uint cchBufferLength);

		[DllImport("kernel32.dll")]
		public static extern IntPtr LocalFree(IntPtr hMem);

		[DllImport("kernel32.dll", SetLastError=true)]
		public static extern uint FormatMessage(uint dwFlags, IntPtr lpSource, int dwMessageId, uint dwLanguageId, ref IntPtr lpBuffer, uint nSize, IntPtr Arguments);
	}
}

using System;
using System.Runtime.InteropServices;

namespace PureInvoke.v3.LsaLookup
{
	[StructLayout(LayoutKind.Sequential)]
	// ReSharper disable once InconsistentNaming
	public struct LSA_OBJECT_ATTRIBUTES
	{
		public uint Length;
		public IntPtr RootDirectory;
		public LSA_UNICODE_STRING ObjectName;
		public uint Attributes;
		public IntPtr SecurityDescriptor;
		public IntPtr SecurityQualityOfService;
	}

}

# PureInvoke PowerShell Module README

## Overview

The PureInvoke module contains functions that handles the complexity of using
[P/Invoke](https://learn.microsoft.com/en-us/dotnet/standard/native-interop/pinvoke) to call Win32 APIs.

There is no native way to call Win32 APIs in PowerShell. In order to use P/Invoke, you have to compile C# code into an
assembly, or use PowerShell's `Add-Type` cmdlet to compile it dynamically at runtime. But then you have to worry about
converting all the native handles and pointer to and from .NET objects.

The PureInvoke solves this by wrapping Win32 APIs with PowerShell functions that take and return .NET objects and does
all the work of converting to and from .NET and Win32 APIs.

## System Requirements

* Windows
* Windows PowerShell 5.1
* PowerShell 6+

## Installing

To install globally:

```powershell
Install-Module -Name 'PureInvoke'
Import-Module -Name 'PureInvoke'
```

To install privately:

```powershell
Save-Module -Name 'PureInvoke' -Path '.'
Import-Module -Name '.\PureInvoke'
```

## Usage

## Commands

### From advapi32.dll

#### Accounts (winbase.h)

| Win32 Function | PureInvoke Function |
| -------------- | ------------------- |
| [`LookupAccountName`](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupaccountnamew) | `Invoke-AdvApiLookupAccountName` |
| [`LookupAccountSid`](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupaccountsidw) | `Invoke-AdvApiLookupAccountSid` |

#### Rights and Privileges (netsecapi.h)

| Win32 Function | PureInvoke Function |
| -------------- | ------------------- |
| [`LsaAddAccountRights`](https://learn.microsoft.com/en-us/windows/win32/api/ntsecapi/nf-ntsecapi-lsaaddaccountrights) | `Invoke-AdvApiLsaAddAccountRights` |
| [`LsaClose`](https://learn.microsoft.com/en-us/windows/win32/api/ntsecapi/nf-ntsecapi-lsaclose) | `Invoke-AdvApiLsaClose` |
| [`LsaEnumerateAccountRights`](https://learn.microsoft.com/en-us/windows/win32/api/ntsecapi/nf-ntsecapi-lsaenumerateaccountrights) | `Invoke-AdvApiLsaEnumerateAccountRights` |
| [`LsaFreeMemory`](https://learn.microsoft.com/en-us/windows/win32/api/ntsecapi/nf-ntsecapi-lsafreememory) | `Invoke-AdvApiLsaFreeMemory` |
| [`LsaNtStatusToWinError`](https://learn.microsoft.com/en-us/windows/win32/api/ntsecapi/nf-ntsecapi-lsantstatustowinerror) | `Invoke-AdvApiLsaNtStatusToWinError` |
| [`LsaOpenPolicy`](https://learn.microsoft.com/en-us/windows/win32/api/ntsecapi/nf-ntsecapi-lsaopenpolicy) | `Invoke-AdvApiLsaOpenPolicy` |
| [`LsaRemoveAccountRights`](https://learn.microsoft.com/en-us/windows/win32/api/ntsecapi/nf-ntsecapi-lsaremoveaccountrights) | `Invoke-AdvApiLsaRemoveAccountRights` |

### From kernel32.dll

#### File System (fileapi.h)

| Win32 Function | PureInvoke Function |
| -------------- | ------------------- |
| [`FindFirstFileNameW`](https://learn.microsoft.com/en-us/windows/win32/api/FileAPI/nf-fileapi-findfirstfilenamew) and [`FindNextFileNameW`](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findnextfilenamew) | `Invoke-KernelFindFileName` |
| [`GetVolumePathNameW`](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getvolumepathnamew) | `Invoke-KernelGetVolumePathName` |

### From netapi32.dll

#### Local Groups (lmaccess.h)

| Win32 Function | PureInvoke Function |
| -------------- | ------------------- |
| [`NetLocalGroupGetMembers`](https://learn.microsoft.com/en-us/windows/win32/api/lmaccess/nf-lmaccess-netlocalgroupgetmembers) | `Invoke-NetApiNetLocalGroupGetMembers` |

## Troubleshooting

The PureInvoke module uses PowerShell's `Add-Type` function to compile the C# P/Invoke code it needs. It only compiles
code when it is needed. Unfortunately, `Add-Type` isn't very resilient. Aggressive anti-virus or other problems can
cause `Add-Type` to fail. By default, PureInvoke will retry failed compilations up to five times. After the first
failure, it waits 100ms before attempting another compilation. After each subsequent failure, it doubles the amount of
time it waits before compiling again, i.e. it will wait 100ms after the first failure, 200ms after the second, 400ms
after the third, etc.

You can control how many times PureInvoke attempts a re-compilation and its initial wait time with the
`PUREINVOKE_MAX_COMPILATION_ATTEMPTS` and `PUREINVOKE_WAIT_MS_BETWEEN_COMPILATION_FAILURES` environment variables. Both
these environmen variables must be positive integers.

You can also control the temp directory PureInvoke uses when it calls `Add-Type` with the `PUREINVOKE_TMP_PATH`
environment variable. Its value must be an absolute path to a directory. If the directory doesn't exist, it is created.

The environment variables must be in place when PureInvoke is first imported. Setting or changing them after importing
PureInvoke will have no effect.

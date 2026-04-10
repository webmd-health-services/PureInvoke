# PureInvoke PowerShell Module README

## Overview

The PureInvoke module contains functions that handles the complexity of using P/Invoke to call Win32 APIs.

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

* `LookupAccountName`: `Invoke-AdvApiLookupAccountName`
* `LookupAccountSid`: `Invoke-AdvApiLookupAccountSid`
* `LsaAddAccountRights`: `Invoke-AdvApiLsaAddAccountRights`
* `LsaClose`: `Invoke-AdvApiLsaClose`
* `LsaEnumerateAccountRights`: `Invoke-AdvApiLsaEnumerateAccountRights`
* `LsaFreeMemory`: `Invoke-AdvApiLsaFreeMemory`
* `LsaNtStatusToWinError`: `Invoke-AdvApiLsaNtStatusToWinError`
* `LsaOpenPolicy`: `Invoke-AdvApiLsaOpenPolicy`
* `LsaRemoveAccountRights`: `Invoke-AdvApiLsaRemoveAccountRights`

### From kernel32.dll

* `Invoke-KernelFindFileName`
* `Invoke-KernelGetVolumePathName`

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

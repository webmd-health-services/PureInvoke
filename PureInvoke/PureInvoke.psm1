# Copyright WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

using namespace System.ComponentModel
using namespace System.Runtime.InteropServices
using namespace System.Security.Principal
using namespace System.Text

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

if (-not (Test-Path -Path 'variable:IsWindows'))
{
    $script:IsWindows = $true
    $script:IsLinux = $script:IsMacOS = $false
}

# Functions should use $script:moduleRoot as the relative root from which to find
# things. A published module has its function appended to this file, while a
# module in development has its functions in the Functions directory.
$script:moduleRoot = $PSScriptRoot

$script:namespace = "PureInvoke"

[int]$script:maxCompiliationAttempts = 5
if ((Test-Path -Path 'env:PUREINVOKE_MAX_COMPILATION_ATTEMPTS'))
{
    [int]$envMaxCompilationAttempts = $script:maxCompiliationAttempts
    if (-not [int]::TryParse($env:PUREINVOKE_MAX_COMPILATION_ATTEMPTS, [ref] $envMaxCompilationAttempts))
    {
        $msg = "Ignoring PUREINVOKE_MAX_COMPILATION_ATTEMPTS value ""${env:PUREINVOKE_MAX_COMPILATION_ATTEMPTS}"" " +
               'because it is not an integer.'
        Write-Warning -Message $msg
    }
    elseif ($envMaxCompilationAttempts -lt 0)
    {
        $msg = "Ignoring PUREINVOKE_MAX_COMPILATION_ATTEMPTS value ""${env:PUREINVOKE_MAX_COMPILATION_ATTEMPTS}"" " +
               'because it is less than 0.'
        Write-Warning -Message $msg
    }
    else
    {
        $script:maxCompiliationAttempts = $envMaxCompilationAttempts
    }
}

[int]$script:waitMsBetweenFailures = 100
if ((Test-Path -Path 'env:PUREINVOKE_WAIT_MS_BETWEEN_COMPILATION_FAILURES'))
{
    [int]$envWaitMsBetweenFailures = $script:waitMsBetweenFailures
    if (-not [int]::TryParse($env:PUREINVOKE_WAIT_MS_BETWEEN_COMPILATION_FAILURES, [ref] $envWaitMsBetweenFailures))
    {
        $msg = "Ignoring PUREINVOKE_WAIT_MS_BETWEEN_COMPILATION_FAILURES value " +
               """${env:PUREINVOKE_WAIT_MS_BETWEEN_COMPILATION_FAILURES}"" because it is not an integer."
        Write-Warning -Message $msg
    }
    elseif ($envWaitMsBetweenFailures -lt 0)
    {
        $msg = "Ignoring PUREINVOKE_WAIT_MS_BETWEEN_COMPILATION_FAILURES value " +
               """${env:PUREINVOKE_WAIT_MS_BETWEEN_COMPILATION_FAILURES}"" because it is less than 0."
        Write-Warning -Message $msg
    }
    else
    {
        $script:waitMsBetweenFailures = $envWaitMsBetweenFailures
    }
}

# If `$script:tmpPath` is set, `Add-PInvokeType` changes the temp path environment variable to `$script:tmpPath` before
# using `Add-Type` to compile its types. By default, uses Add-Type's default behavior, which is to use the value of the
# temp path environment variable for the current platform (`TMP` on Windows, `TMPDIR` on Linux/macOS).
[string] $script:tmpPath = $null
if ((Test-Path -Path 'env:PUREINVOKE_TMP_PATH') -and $env:PUREINVOKE_TMP_PATH)
{
    $script:tmpPath = $env:PUREINVOKE_TMP_PATH
    if (-not [IO.Path]::IsPathRooted($script:tmpPath))
    {
        Write-Warning "Ignoring PUREINVOKE_TMP_PATH value ""${script:tmpPath}"" because it is a relative path. "
        $script:tmpPath = $null
    }

    if ((Test-Path -Path $script:tmpPath -PathType Leaf))
    {
        Write-Warning "Ignoring PUREINVOKE_TMP_PATH value ""${script:tmpPath}"" because it is a file."
    }
}

# The name of the environmen variable that Add-Type uses when writing files.
$script:tmpPathEnvVarName = 'TMPDIR'
if ($IsWindows)
{
    $script:tmpPathEnvVarName = 'TMP'
}

# Constants
[IntPtr] $script:invalidHandle = -1
$script:maxPath = 65535

# https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes
enum PureInvoke_ErrorCode
{
    Ok                       = 0x000
    NERR_Success             = 0x000
    Success                  = 0x000
    InvalidFunction          = 0x001
    FileNotFound             = 0x002
    AccessDenied             = 0x005
    InvalidHandle            = 0x006
    HandleEof                = 0x026    #   38
    InvalidParameter         = 0x057    #   87
    InsufficientBuffer       = 0x07A    #  122
    AlreadyExists            = 0x0B7    #  183
    EnvVarNotFound           = 0x0cb    #  203
    MoreData                 = 0x0ea    #  234
    NoMoreItems              = 0x103    #  259
    InvalidFlags             = 0x3EC    # 1004
    ServiceMarkedForDelete   = 0x430    # 1072
    NoneMapped               = 0x534    # 1332
    NoSuchAlias              = 0x560    # 1376
    MemberNotInAlias         = 0x561    # 1377
    MemberInAlias            = 0x562    # 1378
    NoSuchMember             = 0x56B    # 1387
    InvalidMember            = 0x56C    # 1388
    NERR_GroupNotFound       = 0x8AC    # 2220
    NERR_InvalidComputer     = 0x92f    # 2351
}

# https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lsad/b61b7268-987a-420b-84f9-6c75f8dc8558
[Flags()]
enum PureInvoke_LsaLookup_PolicyAccessRights
{
    LocalInformation = 0x1
    AuditInformation = 0x2
    GetPrivateInformation = 0x4
    TrustAdmin = 0x8
    CreateAccount = 0x10
    CreateSecret = 0x20
    CreatePrivilege = 0x40
    SetQuotaDefaultLimits = 0x80
    SetAuditRequirements = 0x100
    AuditLogAdmin = 0x200
    ServerAdmin = 0x400
    LookupNames = 0x800
    Notification = 0x1000
}

# https://learn.microsoft.com/en-us/windows/win32/api/winnt/ne-winnt-sid_name_use
enum PureInvoke_SidNameUse
{
    User = 1
    Group = 2
    Domain = 3
    Alias = 4
    WellKnownGroup = 5
    DeletedAccount = 6
    Invalid = 7
    Unknown = 8
    Computer = 9
    Label = 10
    LogonSession = 11
}

# Store each of your module's functions in its own file in the Functions
# directory. On the build server, your module's functions will be appended to
# this file, so only dot-source files that exist on the file system. This allows
# developers to work on a module without having to build it first. Grab all the
# functions that are in their own files.
$functionsPath = Join-Path -Path $script:moduleRoot -ChildPath 'Functions\*.ps1'
if( (Test-Path -Path $functionsPath) )
{
    foreach( $functionPath in (Get-Item $functionsPath) )
    {
        . $functionPath.FullName
    }
}

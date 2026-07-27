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
using namespace System.Security.AccessControl
using namespace System.Security.Principal
using namespace System.ServiceProcess
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

Add-Type -AssemblyName 'System.ServiceProcess'

# https://learn.microsoft.com/en-us/windows/win32/debug/system-error-codes
enum PureInvoke_ErrorCode
{
    Ok                       =    0
    NERR_Success             =    0
    Success                  =    0
    InvalidFunction          =    1
    FileNotFound             =    2
    AccessDenied             =    5
    InvalidHandle            =    6
    HandleEof                =   38 # 0x026
    InvalidParameter         =   87 # 0x057
    InsufficientBuffer       =  122 # 0x07A
    AlreadyExists            =  183 # 0x0B7
    EnvVarNotFound           =  203 # 0x0cb
    MoreData                 =  234 # 0x0ea
    NoMoreItems              =  259 # 0x103
    InvalidFlags             = 1004 # 0x3EC
    ServiceMarkedForDelete   = 1072 # 0x430
    NoneMapped               = 1332 # 0x534
    NoSuchAlias              = 1376 # 0x560
    MemberNotInAlias         = 1377 # 0x561
    MemberInAlias            = 1378 # 0x562
    NoSuchMember             = 1387 # 0x56B
    InvalidMember            = 1388 # 0x56C
    NERR_GroupNotFound       = 2220 # 0x8AC
    NERR_InvalidComputer     = 2351 # 0x92f
}

# https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lsad/b61b7268-987a-420b-84f9-6c75f8dc8558
[Flags()]
enum PureInvoke_LsaLookup_PolicyAccessRights
{
    LocalInformation      = 0x0001
    AuditInformation      = 0x0002
    GetPrivateInformation = 0x0004
    TrustAdmin            = 0x0008
    CreateAccount         = 0x0010
    CreateSecret          = 0x0020
    CreatePrivilege       = 0x0040
    SetQuotaDefaultLimits = 0x0080
    SetAuditRequirements  = 0x0100
    AuditLogAdmin         = 0x0200
    ServerAdmin           = 0x0400
    LookupNames           = 0x0800
    Notification          = 0x1000
}

# https://learn.microsoft.com/en-us/windows/win32/api/winnt/ne-winnt-sid_name_use
enum PureInvoke_SidNameUse
{
    User           =  1
    Group          =  2
    Domain         =  3
    Alias          =  4
    WellKnownGroup =  5
    DeletedAccount =  6
    Invalid        =  7
    Unknown        =  8
    Computer       =  9
    Label          = 10
    LogonSession   = 11
}

# PowerShell doesn't let enumerations use values defined in the same enumeration, so create private enums so we only
# define each flag once.


# https://learn.microsoft.com/en-us/windows/win32/secauthz/access-mask
enum _AccessMask
{
    Delete                 = 0x00010000
    ReadControl            = 0x00020000
    WriteDac               = 0x00040000
    WriteOwner             = 0x00080000
    Synchronize            = 0x00100000
    StandardRightsRead     = 0x00020000
    StandardRightsWrite    = 0x00020000
    StandardRightsExecute  = 0x00020000
    StandardRightsRequired = 0x000f0000
    StandardRigtsAll       = 0x001f0000
    SpecificRightsAll      = 0x0000ffff
    AccessSystemSecurity   = 0x01000000
    MaximumAllowed         = 0x02000000
    GenericAll             = 0x10000000
    GenericExecute         = 0x20000000
    GenericWrite           = 0x40000000
    GenericRead            = 0x80000000
}

# https://learn.microsoft.com/en-us/windows/win32/secauthz/generic-access-rights#generic-access-rights-constants
[Flags()]
enum _ScmAccessRights
{
    Connect             = 0x00000001
    CreateService       = 0x00000002
    EnumerateService    = 0x00000004
    Lock                = 0x00000008
    QueryLockStatus     = 0x00000010
    ModifyBootConfig    = 0x00000020
}

# https://learn.microsoft.com/en-us/windows/win32/services/service-security-and-access-rights#access-rights-for-the-service-control-manager
[Flags()]
enum PureInvoke_SCManagerAccessRights
{
    # Specific access rights
    CreateService       = [_ScmAccessRights]::CreateService
    Connect             = [_ScmAccessRights]::Connect
    EnumerateService    = [_ScmAccessRights]::EnumerateService
    Lock                = [_ScmAccessRights]::Lock
    ModifyBootConfig    = [_ScmAccessRights]::ModifyBootConfig
    QueryLockStatus     = [_ScmAccessRights]::QueryLockStatus

    All                 = [_AccessMask]::StandardRightsRequired -bor
                          [_ScmAccessRights]::Connect -bor
                          [_ScmAccessRights]::CreateService -bor
                          [_ScmAccessRights]::EnumerateService -bor
                          [_ScmAccessRights]::Lock -bor
                          [_ScmAccessRights]::QueryLockStatus -bor
                          [_ScmAccessRights]::ModifyBootConfig

    # Generic access rights
    Read                = [_AccessMask]::StandardRightsRead -bor
                          [_ScmAccessRights]::EnumerateService -bor
                          [_ScmAccessRights]::QueryLockStatus

    Write               = [_AccessMask]::StandardRightsWrite -bor
                          [_ScmAccessRights]::CreateService -bor
                          [_ScmAccessRights]::ModifyBootConfig

    Execute             = [_AccessMask]::StandardRightsExecute -bor
                          [_ScmAccessRights]::Connect -bor
                          [_ScmAccessRights]::Lock
}

enum _ServiceAccessRights
{
    QueryConfig             = 0x00000001
    ChangeConfig            = 0x00000002
    QueryStatus             = 0x00000004
    EnumerateDependents     = 0x00000008
    Start                   = 0x00000010
    Stop                    = 0x00000020
    PauseContinue           = 0x00000040
    Interrogate             = 0x00000080
    UserDefinedControl      = 0x00000100
}

# https://learn.microsoft.com/en-us/windows/win32/services/service-security-and-access-rights#access-rights-for-a-service
[Flags()]
enum PureInvoke_ServiceAccessRights
{
    # Specific access rights.
    ChangeConfig            = [_ServiceAccessRights]::ChangeConfig
    EnumerateDependents     = [_ServiceAccessRights]::EnumerateDependents
    Interrogate             = [_ServiceAccessRights]::Interrogate
    PauseContinue           = [_ServiceAccessRights]::PauseContinue
    QueryConfig             = [_ServiceAccessRights]::QueryConfig
    QueryStatus             = [_ServiceAccessRights]::QueryStatus
    Start                   = [_ServiceAccessRights]::Start
    Stop                    = [_ServiceAccessRights]::Stop
    UserDefinedControl      = [_ServiceAccessRights]::UserDefinedControl

    AllAccess               = [_AccessMask]::StandardRightsRequired -bor
                              [_ServiceAccessRights]::ChangeConfig -bor
                              [_ServiceAccessRights]::EnumerateDependents -bor
                              [_ServiceAccessRights]::Interrogate -bor
                              [_ServiceAccessRights]::PauseContinue -bor
                              [_ServiceAccessRights]::QueryConfig -bor
                              [_ServiceAccessRights]::QueryStatus -bor
                              [_ServiceAccessRights]::Start -bor
                              [_ServiceAccessRights]::Stop -bor
                              [_ServiceAccessRights]::UserDefinedControl

    # Standard access rights.
    AccessSystemSecurity    = [_AccessMask]::AccessSystemSecurity
    Delete                  = [_AccessMask]::Delete
    ReadControl             = [_AccessMask]::ReadControl
    WriteDac                = [_AccessMask]::WriteDac
    WriteOwner              = [_AccessMask]::WriteOwner

    # Generic access rights
    Read                    = [_AccessMask]::StandardRightsRead -bor
                              [_ServiceAccessRights]::QueryConfig -bor
                              [_ServiceAccessRights]::QueryStatus -bor
                              [_ServiceAccessRights]::Interrogate -bor
                              [_ServiceAccessRights]::EnumerateDependents

    Write                   = [_AccessMask]::StandardRightsWrite -bor
                              [_ServiceAccessRights]::ChangeConfig

    Execute                 = [_AccessMask]::StandardRightsExecute -bor
                              [_ServiceAccessRights]::Start -bor
                              [_ServiceAccessRights]::Stop -bor
                              [_ServiceAccessRights]::PauseContinue -bor
                              [_ServiceAccessRights]::UserDefinedControl
}

# https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw
[Flags()]
enum PureInvoke_ServiceErrorControl
{
    Ignore   = 0
    Normal   = 1
    Severe   = 2
    Critical = 3
}

# https://learn.microsoft.com/en-us/windows/win32/api/winsvc/nf-winsvc-queryserviceconfig2w
[Flags()]
enum PureInvoke_ServiceInfoLevel
{
    Description        =  1
    FailureActions     =  2
    DelayedAutoStart   =  3
    FailureActionsFlag =  4
    SidType            =  5
    RequiredPrivileges =  6
    Preshutdown        =  7
    Triggers           =  8
    PreferredNode      =  9
    LaunchProtected    = 12
}

# https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-sc_action
# https://github.com/tpn/winsdk-10/blob/master/Include/10.0.16299.0/um/winsvc.h#L522-L528
enum PureInvoke_ServiceFailureAction
{
    None       = 0
    Restart    = 1
    Reboot     = 2
    RunCommand = 3
    OwnRestart = 4
}

# https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_sid_info
enum PureInvoke_ServiceSidType
{
    None         = 0
    Unrestricted = 1
    Restricted   = 3
}

# https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger
# https://github.com/tpn/winsdk-10/blob/master/Include/10.0.16299.0/um/winsvc.h#L318-L326
enum PureInvoke_ServiceTriggerType
{
    DeviceInterfaceArrival  =  1
    IPAddressAvailability   =  2
    DomainJoin              =  3
    FirewallPortEvent       =  4
    GroupPolicy             =  5
    NetworkEndpoint         =  6
    CustomSystemStateChange =  7
    Custom                  = 20
    Aggregate               = 30
}

# https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_launch_protected_info
enum PureInvoke_ServiceProtectionType
{
    None             = 0
    Windows          = 1
    WindowsLight     = 2
    AntimalwareLight = 3
}

# https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger
enum PureInvoke_ServiceTriggerAction
{
    Start = 1
    Stop  = 2
}

# https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger_specific_data_item
enum PureInvoke_ServiceTriggerDataType
{
    Binary     = 1
    String     = 2
    Level      = 3
    KeywordAny = 4
    KeywordAll = 5
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

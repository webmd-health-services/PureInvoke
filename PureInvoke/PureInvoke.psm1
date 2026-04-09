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

# Functions should use $script:moduleRoot as the relative root from which to find
# things. A published module has its function appended to this file, while a
# module in development has its functions in the Functions directory.
$script:moduleRoot = $PSScriptRoot

Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'bin\netstandard2.0\PureInvoke.v3.dll' -Resolve)

# Constants
[IntPtr] $script:invalidHandle = -1
$script:maxPath = 65535

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

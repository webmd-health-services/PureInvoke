
using namespace System.Security.AccessControl
using namespace System.Security.Principal

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\PureInvoke" -Resolve) -Verbose:$false

    $script:scmHandle = Invoke-AdvApiOpenSCManager
    $script:svcHandle = [IntPtr]::Zero

    function ThenSecurityDescriptor
    {
        param(
            [Parameter(Mandatory)]
            [RawSecurityDescriptor] $SecurityDescriptor,

            [Parameter(Mandatory)]
            [SecurityInfos] $HasSections
        )

        if ($HasSections.HasFlag([SecurityInfos]::DiscretionaryAcl))
        {
            $SecurityDescriptor.DiscretionaryAcl | Should -Not -BeNullOrEmpty
            $SecurityDescriptor.DiscretionaryAcl | Should -BeOfType ([CommonAce])
        }
        else
        {
            $SecurityDescriptor.DiscretionaryAcl | Should -BeNullOrEmpty
        }

        if ($HasSections.HasFlag([SecurityInfos]::Group))
        {
            $SecurityDescriptor.Group | Should -Not -BeNullOrEmpty
            $SecurityDescriptor.Group | Should -BeOfType ([SecurityIdentifier])
        }
        else
        {
            $SecurityDescriptor.Group | Should -BeNullOrEmpty
        }


        if ($HasSections.HasFlag([SecurityInfos]::Owner))
        {
            $SecurityDescriptor.Owner | Should -Not -BeNullOrEmpty
            $SecurityDescriptor.Owner | Should -BeOfType ([SecurityIdentifier])
        }
        else
        {
            $SecurityDescriptor.Owner | Should -BeNullOrEmpty
        }

        if ($HasSections.HasFlag([SecurityInfos]::SystemAcl))
        {
            $SecurityDescriptor.SystemAcl | Should -Not -BeNullOrEmpty
        }
        else
        {
            $SecurityDescriptor.SystemAcl | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Invoke-ADvApiCloseServiceHandle -Handle $script:scmHandle
}

Describe 'Invoke-AdvApiQueryServiceObjectSecurity' {
    BeforeEach {
        $Global:Error.Clear()
    }

    $svcNames = Get-Service | Select-Object -ExpandProperty 'Name'
    Context '<_>' -ForEach $svcNames {
        BeforeAll {
            $script:svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle -ServiceName $_
        }

        AfterAll {
            $script:svcHandle | Invoke-AdvApiCloseServiceHandle
        }

        It 'queries <_> security information' -ForEach ([Enum]::GetValues([SecurityInfos])) {
            if ($_.HasFlag([SecurityInfos]::SystemAcl))
            {
                $sd = Invoke-AdvApiQueryServiceObjectSecurity -ServiceHandle $script:svcHandle `
                                                              -SecurityInformation $_ `
                                                              -ErrorAction SilentlyContinue
                $Global:Error | Should -Match 'Access is denied'
                $sd | Should -BeNullOrEmpty
                return
            }

            $sd = Invoke-ADvApiQueryServiceObjectSecurity -ServiceHandle $script:svcHandle -SecurityInformation $_
            $sd | Should -Not -BeNullOrEmpty
            $sd | Should -BeOfType ([RawSecurityDescriptor])
            ThenSecurityDescriptor $sd -HasSections $_
        }
    }

    It 'queries multiple security infos' {
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle -ServiceName 'W32Time'
        $infos = [SecurityInfos]::DiscretionaryAcl -bor [SecurityInfos]::Group -bor [SecurityInfos]::Owner

        try
        {
            $sd = Invoke-AdvApiQueryServiceObjectSecurity -ServiceHandle $svcHandle -SecurityInformation $infos
            $sd | Should -Not -BeNullOrEmpty
            $sd | Should -BeOfType ([RawSecurityDescriptor])
            ThenSecurityDescriptor $sd -HasSections $infos
        }
        finally
        {
            $svcHandle | Invoke-AdvApiCloseServiceHandle
        }
    }
}

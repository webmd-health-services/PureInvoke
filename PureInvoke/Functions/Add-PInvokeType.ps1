
function Add-PInvokeType
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String] $DllName,

        [Parameter(Mandatory)]
        [String] $Definition
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $memStream = [IO.MemoryStream]::New()
    $writer = [IO.StreamWriter]::new($memStream)
    $writer.Write($Definition)
    $writer.Flush()
    $memStream.Position = 0
    $defHash = Get-FileHash -InputStream $memStream
    $defHash = $defHash.Hash.Substring(0, 11).ToLowerInvariant()

    $typeName = "${DllName}${defHash}"
    $namespace = "${script:namespace}.${DllName}"
    $fullTypeName = "${namespace}.${typeName}"

    Write-Debug "Looking for already-compiled ${fullTypeName} type."
    $assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
    for ($idx = $assemblies.Length - 1; $idx -ge 0; $idx--)
    {
        $assembly = $assemblies[$idx]
        $type = $assembly.GetType($fullTypeName, $false)
        if ($type)
        {
            Write-Debug "Found already-compiled ${fullTypeName} type."
            return $type
        }
    }

    Write-Debug "Type ${fullTypeName} not found."

    $originalTmpPath = [IO.Path]::GetTempPath()
    if ($script:tmpPath)
    {
        if (Test-Path -Path $script:tmpPath -PathType Leaf)
        {
            $msg = 'Unable to change temp path because the PUREINVOKE_TMP_PATH environment variable''s value ' +
                   """${script:tmpPath})"" is a path to a file not a directory."
            Write-Warning $msg
        }
        else
        {
            if (-not (Test-Path -Path $script:tmpPath))
            {
                New-Item -Path $script:tmpPath -ItemType Directory -Force | Out-Null
            }
            Write-Debug "Setting ${script:tmpPathEnvVarName} to ""${script:tmpPath}"" (from ""${originalTmpPath}"")."
            [Environment]::SetEnvironmentVariable($script:tmpPathEnvVarName, $script:tmpPath, [EnvironmentVariableTarget]::Process)
        }
    }

    $waitMsBetweenFailures = $script:waitMsBetweenFailures
    $tryNum = 0
    while ($tryNum -lt $script:maxCompiliationAttempts)
    {
        try
        {
            Write-Verbose -Message @"
namespace ${namespace};

class ${typeName}
{
${Definition}
}
"@
            Write-Debug "Compiling type ${fullTypeName}."
            Add-Type -Namespace $namespace `
                     -Name $typeName `
                     -MemberDefinition $Definition `
                     -Using 'System.Text','System.Collections.Generic' `
                     -PassThru `
                     -ErrorAction Stop |
                # Add-Type returns all types that were just compiled. We just want the main class.
                Where-Object 'FullName' -EQ $fullTypeName
            break
        }
        catch
        {
            # No use trying to re-compile something that's busted.
            if ($_.FullyQualifiedErrorId.StartsWith('SOURCE_CODE_ERROR'))
            {
                throw
            }

            $tryNum++
            if ($tryNum -eq ($script:maxCompiliationAttempts - 1))
            {
                throw
            }

            $msg = "Failed to compile ${DllName} ${fullTypeName} class (retrying in ${waitMsBetweenFailures}ms): ${_}."
            if ($waitMsBetweenFailures -gt (10 * 1000))
            {
                $msg = "PureInvoke PowerShell module's Add-PInvokeType function " +
                       "$($msg[0].ToLowerInvariant())$($msg.Substring(1))"
                Write-Warning -Message $msg -WarningAction $WarningPreference
            }
            else
            {
                Write-Verbose -Message $msg
            }
            Start-Sleep -Milliseconds $waitMsBetweenFailures
            $waitMsBetweenFailures *= 2
        }
        finally
        {
            if ($script:tmpPath)
            {
                Write-Debug "Setting ${script:tmpPathEnvVarName} back to ""${originalTmpPath}"" (from ""${script:tmpPath})""."
                [Environment]::SetEnvironmentVariable($script:tmpPathEnvVarName, $originalTmpPath, [EnvironmentVariableTarget]::Process)
            }
        }
    }
}
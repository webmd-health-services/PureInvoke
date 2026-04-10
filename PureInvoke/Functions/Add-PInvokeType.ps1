
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
            Write-Warning -Message "The PUREINVOKE_TMP_PATH ""${script:tmpPath})"" is a file."
        }
        else
        {
            if (-not (Test-Path -Path $script:tmpPath))
            {
                New-Item -Path $script:tmpPath -ItemType Directory -Force | Out-Null
            }
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
            Write-Verbose -Message $msg
            Start-Sleep -Milliseconds $waitMsBetweenFailures
            $waitMsBetweenFailures *= 2
        }
        finally
        {
            if ($script:tmpPath)
            {
                [Environment]::SetEnvironmentVariable($script:tmpPathEnvVarName, $originalTmpPath, [EnvironmentVariableTarget]::Process)
            }
        }
    }
}
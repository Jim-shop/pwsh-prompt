function global:sudo ([Parameter(ValueFromRemainingArguments)][string[]]$arg) {
    if ($arg.Count -ne 0) {
        $private:argList = @("-nop", "-c") + $arg + @(";", "pause")
    }
    elseif ((Get-History).Count -ne 0) {
        $private:argList = @("-nop", "-c", (Get-History -Count 1).CommandLine, ";" , "pause")
    }
    else {
        $private:argList = @()
    }
    Start-Process -FilePath "pwsh" -Verb runAs -Wait -ArgumentList $private:argList
}

function global:chcp ([int]$CodePage = 936) {
    # 65001: Unicode; 936: GB2312
    [System.Console]::InputEncoding = [System.Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding($CodePage)
}

function global:Prompt {
    # 支持conda
    if ($Env:CONDA_PROMPT_MODIFIER) {
        $Env:CONDA_PROMPT_MODIFIER | Write-Host -NoNewline
    }
    # 显示管理员模式
    if ($global:isAdmin) { 
        Write-Host "[ADMIN]" -NoNewline -BackgroundColor red 
        Write-Host " " -NoNewline
    }
    # 打印执行时间
    if (((Get-History).Count -ne 0) -and -not ((Test-Path Variable:\LastCommandID) -and ((Get-History)[-1].Id -eq $global:LastCommandID))) {
        # 如果有执行过命令，但不是没执行新的命令
        $global:LastCommandID = (Get-History)[-1].Id
        $private:lastCommand = Get-History -Count 1
        $private:executionTime = $private:lastCommand.Duration
        $private:displayMSLimit = [System.TimeSpan]::FromSeconds(5)
        if ($private:executionTime -ge $private:displayMSLimit) {
            $private:shortTime = [System.Math]::Round($private:executionTime.TotalSeconds, 1)
            Write-Host -NoNewline -ForegroundColor Blue ("$private:shortTime" + "s ")
        }
        else {
            $private:shortTime = [System.Math]::Round($private:executionTime.TotalMilliseconds)
            Write-Host -NoNewline -ForegroundColor Blue ("$private:shortTime" + "ms ")
        }
    }
    # 如果执行过命令，且命令出错，显示错误代码
    if ($global:LASTEXITCODE) { 
        Write-Host -NoNewline -ForegroundColor Red "[$global:LASTEXITCODE] " 
        $global:LASTEXITCODE = 0
    }
    # 将路径显示在标题中
    $private:shortPath = Get-Location | Split-Path -Leaf
    $global:Host.UI.RawUI.WindowTitle = $private:shortPath
    Write-Host -NoNewline -ForegroundColor Green "$private:shortPath" 
    return " $('→' * ($global:nestedPromptLevel + 1)) " # 改回默认输出颜色
}

# # 切换到Unicode（与conda有兼容性问题）
# chcp(65001)

# 计算Admin身份
$private:identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$private:principal = [Security.Principal.WindowsPrincipal] $private:identity
$private:adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
$global:isAdmin = $private:principal.IsInRole($private:adminRole)
Remove-Item -Path Variable:\identity, Variable:\principal, Variable:\adminRole

# 语法错误高亮
Set-PSReadLineOption -PromptText "→ "
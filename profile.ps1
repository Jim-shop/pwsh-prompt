function global:sudo ([Parameter(ValueFromRemainingArguments)][string[]]$arg) {
    if ($arg.Count -ne 0) {
        $private:argList = @("-nop", "-c") + $arg + @(";", "pause")
        Start-Process -FilePath "pwsh" -Verb runAs -Wait -ArgumentList $private:argList
    } else {
        Write-Error "你要 sudo 什么？"
    }
}

function global:chcp ([int]$CodePage = 936) {
    # 65001: Unicode; 936: GB2312
    [System.Console]::InputEncoding = [System.Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding($CodePage)
}

function global:Prompt {
    # 如果传统 CLI 应用出现错误，打印错误信息
    if ($global:LASTEXITCODE) { 
        $private:errorPrompt = (certutil.exe -error $global:LASTEXITCODE)[0..1] | Join-String -Separator "`r`n"
        Write-Host "`e[91;1m$errorPrompt`e[0m"
        $global:LASTEXITCODE = 0
    }
    # 显示 Conda 环境
    Write-Host -NoNewline $env:CONDA_PROMPT_MODIFIER
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
        if ($private:executionTime -le [System.TimeSpan]::FromSeconds(5)) {
            # <= 5000ms: 毫秒
            $private:timeString = "$([System.Math]::Round($private:executionTime.TotalMilliseconds))ms"
        }
        elseif ($private:executionTime -le [System.TimeSpan]::FromSeconds(60)) {
            # <= 60s: 秒
            $private:timeString = "$([System.Math]::Round($private:executionTime.TotalSeconds, 1))s"
        }
        elseif ($private:executionTime -le [System.TimeSpan]::FromSeconds(3600)) {
            # <= 60min: 分钟
            $private:timeString = "$([System.Math]::Round($private:executionTime.TotalSeconds / 60, 1))min"
        }
        else {
            # > 1h：小时
            $private:timeString = "$([System.Math]::Round($private:executionTime.TotalSeconds / 3600, 1))h"
        }
        Write-Host -NoNewline -ForegroundColor Blue "$private:timeString "
    }
    # 将路径显示在标题中
    $private:shortPath = Get-Location | Split-Path -Leaf
    $global:Host.UI.RawUI.WindowTitle = $private:shortPath
    Write-Host -NoNewline -ForegroundColor Green "$private:shortPath" 
    return " $('→' * ($global:nestedPromptLevel + 1)) " # 改回默认输出颜色
}

# 切换到Unicode（与conda有兼容性问题）
# chcp(65001)

# 计算Admin身份
$private:identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$private:principal = [Security.Principal.WindowsPrincipal] $private:identity
$private:adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
$global:isAdmin = $private:principal.IsInRole($private:adminRole)
Remove-Item -Path Variable:\identity, Variable:\principal, Variable:\adminRole

# 语法错误高亮
Set-PSReadLineOption -PromptText "→ "

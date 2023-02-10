# pwsh prompt

轻量级自定义的pwsh（powershell）提示符。
附带一个改变输入输出编码的函数`chcp`。


## 依赖

- pwsh 7

低版本PowerShell的HistoryInfo对象没有Duration成员，需要做以下兼容性修改：将
```pwsh
$private:executionTime = $private:lastCommand.Duration
```
改成
```pwsh
$private:executionTime = $private:lastCommand.EndExecutionTime - $private:lastCommand.StartExecutionTime
```

## 使用方法

在pwsh中输入
```pwsh
Write-Output $PROFILE
```
获得当前pwsh配置文件路径，使用你喜欢的编译器将项目中`profile.ps1`文件的内容粘贴进去保存，重启pwsh生效。

## 负面影响

会向当前pwsh中泄露一个全局变量`LastCommandID`。
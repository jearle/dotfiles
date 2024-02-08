$PATH_APPLICATIONS="$HOME\Applications"

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$MODULE_POSH_GIT="$PATH_APPLICATIONS\posh-git-1.1.0\src\posh-git.psd1"

Import-Module $MODULE_POSH_GIT

Remove-Item function:mkdir

Remove-Item alias:rm
Remove-Item alias:ls
Remove-Item alias:echo
Remove-Item alias:cat

$BIN_UNIX_UTILS="$PATH_APPLICATIONS\git-2.43.0\usr\bin"
$BIN_NVIM = "$PATH_APPLICATIONS\nvim\bin"
$BIN_FZF = "$PATH_APPLICATIONS\fzf"
$BIN_FD = "$PATH_APPLICATIONS\fd-gnu-9.0.0"
$BIN_LSD = "$PATH_APPLICATIONS\lsd-gnu-1.0.0"
$BIN_BAT = "$PATH_APPLICATIONS\bat-gnu-0.24.0"
$BIN_ZOXIDE = "$PATH_APPLICATIONS\zoxide-msvc-0.9.2"

$env:PATH += "" +
  ";$BIN_UNIT_UTILS" +
  ";$BIN_NVIM" +
  ";$BIN_FZF" +
  ";$BIN_LSD" +
  ";$BIN_BAT" +
  ";$BIN_ZOXIDE" +
  ""

$colorYellow = 0xd7d7af
$colorGreen = 0x00d787
$colorRed = 0xe06c75

$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$GitPromptSettings.DefaultPromptWriteStatusFirst = $true

$GitPromptSettings.DefaultPromptPrefix.Text = "`n"

$GitPromptSettings.DefaultPromptPath.Text = '`n$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")'
$GitPromptSettings.DefaultPromptPath.ForegroundColor = $colorYellow 

$GitPromptSettings.DefaultPromptBeforeSuffix.Text = '`n$(pwd)'
$GitPromptSettings.DefaultPromptBeforeSuffix.ForegroundColor = $colorGreen

$GitPromptSettings.DefaultPromptSuffix.Text =  "`n> "
$GitPromptSettings.DefaultPromptSuffix.ForegroundColor = $colorRed

#$GitPromptSettings.DefaultPromptWriteStatusFirst = $true
#$GitPromptSettings.DefaultPromptBeforeSuffix.Text = "`n$([DateTime]::now.ToString("MM-dd HH:mm:ss"))"
#$GitPromptSettings.DefaultPromptBeforeSuffix.ForegroundColor = 0x808080
#$GitPromptSettings.DefaultPromptSuffix = ' $((Get-History -Count 1).id + 1)$(">" * ($nestedPromptLevel + 1)) '

function ls {
  lsd -lah $args
}

#function prompt {
#
#  Write-Host
#  Write-Host $GitPromptSettings.DefaultPromptPrefix
#  Write-Host $date -ForegroundColor $colorYellow 
#  Write-Host $pwd -ForegroundColor $colorGreen
#  Write-Host ">" -ForegroundColor $colorRed -NoNewline
#
#  return " "
#}

function ViModeChangeHandler {
  if ($args[0] -eq 'Command') {
    # Set the cursor to a blinking block.
    Write-Host -NoNewLine "`e[2 q"
  } else {
    # Set the cursor to a blinking line.
    Write-Host -NoNewLine "`e[6 q"
  }
}

Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $Function:ViModeChangeHandler

$z = zoxide init powershell | Out-String
Invoke-Expression $z

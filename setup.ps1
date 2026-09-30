<#
Installs Kanika's voice into an existing GPT-SoVITS v2Pro install (Windows).

    .\setup.ps1
    .\setup.ps1 -GsvHome "D:\GPT-SoVITS-v2pro-20250604"
    .\setup.ps1 -Zip C:\Downloads\kanika-voice.zip       # already downloaded

Downloads kanika-voice.zip from this repo's Releases (private: needs `gh auth
login` with an account that has access) and unpacks it into the GPT-SoVITS
folder. Adds files only; touches nothing that is already there except its own.
Safe to re-run.
#>
param(
    [string]$GsvHome = $(if ($env:GSV_HOME) { $env:GSV_HOME } else { "C:\GPT-SoVITS-v2pro-20250604" }),
    [string]$Repo = "zhuhongd/kanika-voice",
    [string]$Zip = ""
)
$ErrorActionPreference = "Stop"

function Step($n, $msg) { Write-Host "`n[$n] $msg" -ForegroundColor Cyan }
function Ok($msg)       { Write-Host "      $msg" -ForegroundColor DarkGray }

Step 1 "GPT-SoVITS v2Pro"
foreach ($f in "runtime\python.exe", "api_v2.py", "GPT_SoVITS\pretrained_models\v2Pro\s2Gv2Pro.pth") {
    if (-not (Test-Path (Join-Path $GsvHome $f))) {
        throw @"
GPT-SoVITS v2Pro not found at $GsvHome (missing $f).

  1. Download GPT-SoVITS-v2pro-20250604.7z (~7.7 GB) from
     https://github.com/RVC-Boss/GPT-SoVITS/releases
  2. Extract it. The folder must contain runtime\python.exe
  3. Re-run this script, with -GsvHome "<that folder>" if it is not
     C:\GPT-SoVITS-v2pro-20250604
"@
    }
}
Ok "found at $GsvHome"

Step 2 "kanika-voice.zip"
$downloaded = $false
if (-not $Zip) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI (gh) not found. Install it from https://cli.github.com, run 'gh auth login', then re-run."
    }
    $Zip = Join-Path $env:TEMP "kanika-voice.zip"
    Ok "downloading from $Repo (269 MB) ..."
    gh release download --repo $Repo --pattern "kanika-voice.zip" --output $Zip --clobber
    if ($LASTEXITCODE -ne 0) { throw "Download failed. Check that your gh account has access to $Repo." }
    $downloaded = $true
}
if (-not (Test-Path $Zip)) { throw "Zip not found: $Zip" }
Ok $Zip

Step 3 "Unpacking into $GsvHome"
Expand-Archive -Path $Zip -DestinationPath $GsvHome -Force
if ($downloaded) { Remove-Item $Zip -Force }
$expected = "GPT_weights_v2Pro\kanika-e15.ckpt", "SoVITS_weights_v2Pro\kanika_e8_s288.pth",
            "GPT_SoVITS\configs\tts_infer_kanika.yaml", "voices\kanika\refs\conversational.wav"
foreach ($f in $expected) {
    if (-not (Test-Path (Join-Path $GsvHome $f))) { throw "Unpack incomplete: missing $f" }
    Ok $f
}

Write-Host "`nDone." -ForegroundColor Green
if ($GsvHome -ne "C:\GPT-SoVITS-v2pro-20250604" -and $env:GSV_HOME -ne $GsvHome) {
    Write-Host "Your GPT-SoVITS is not at the default path. Tell start_server.bat where it is, once:"
    Write-Host "    setx GSV_HOME `"$GsvHome`"      (then open a new terminal)"
}
Write-Host "Next:  start_server.bat, then  python say.py `"Hi! Good morning.`""

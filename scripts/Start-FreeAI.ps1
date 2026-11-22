param([string]$Model = 'qwen2.5:1.5b')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$runtimeDir = Join-Path $projectRoot '.runtime/ollama'
$baseUrl = 'http://127.0.0.1:11434'

function Test-LocalAI {
    try { $null = Invoke-RestMethod "$baseUrl/api/version" -TimeoutSec 3; return $true }
    catch { return $false }
}

try {
    New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
    $ollamaPath = Join-Path $runtimeDir 'ollama.exe'
    $installed = Get-Command ollama -ErrorAction SilentlyContinue
    $userInstall = Join-Path $env:LOCALAPPDATA 'Programs/Ollama/ollama.exe'
    if ($installed) { $ollamaPath = $installed.Source }
    elseif (Test-Path -LiteralPath $userInstall) { $ollamaPath = $userInstall }
    if (-not (Test-LocalAI)) {
        if (-not (Test-Path -LiteralPath $ollamaPath)) {
            Write-Host 'Downloading Ollama from its official GitHub release. Several GB of free disk space are required.'
            $archive = Join-Path $runtimeDir 'ollama-windows-amd64.zip'
            $oldProgress = $ProgressPreference
            try {
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest 'https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip' -OutFile $archive -UseBasicParsing
            } finally { $ProgressPreference = $oldProgress }
            Expand-Archive -LiteralPath $archive -DestinationPath $runtimeDir -Force
            if (-not (Test-Path -LiteralPath $ollamaPath)) { throw 'Ollama executable not found after extraction.' }
        }
        $env:OLLAMA_HOST = '127.0.0.1:11434'
        $env:OLLAMA_MODELS = Join-Path $runtimeDir 'models'
        $env:OLLAMA_NO_CLOUD = '1'
        Start-Process -FilePath $ollamaPath -ArgumentList 'serve' -WindowStyle Hidden -WorkingDirectory $runtimeDir -RedirectStandardOutput (Join-Path $runtimeDir 'server.log') -RedirectStandardError (Join-Path $runtimeDir 'server-error.log') | Out-Null
        for ($attempt=0; $attempt -lt 30; $attempt++) {
            if (Test-LocalAI) { break }
            Start-Sleep -Seconds 1
        }
        if (-not (Test-LocalAI)) { throw 'Ollama did not start. See .runtime/ollama/server-error.log.' }
    }

    $models = Invoke-RestMethod "$baseUrl/api/tags" -TimeoutSec 10
    if ($Model -notin @($models.models | ForEach-Object { $_.name })) {
        Write-Host "Downloading $Model once (default model is about 1 GB). Please wait..."
        # Consume line-delimited progress without a long, silent buffered request.
        $env:OLLAMA_HOST = '127.0.0.1:11434'
        if (Test-Path -LiteralPath $ollamaPath) {
            & $ollamaPath pull $Model
            if ($LASTEXITCODE -ne 0) { throw 'Model download failed. Check Internet access and run this file again.' }
        } else {
            $pull = Invoke-RestMethod "$baseUrl/api/pull" -Method Post -ContentType 'application/json' -Body (@{model=$Model;stream=$false}|ConvertTo-Json) -TimeoutSec 3600
            if ($pull.status -ne 'success') { throw 'Model download did not complete.' }
        }
    }
    Write-Host 'Checking a real AI reply. First load can take a few minutes...'
    $body = @{model=$Model;stream=$false;messages=@(@{role='user';content='Say hello briefly.'});options=@{num_predict=30}} | ConvertTo-Json -Depth 8
    $reply = Invoke-RestMethod "$baseUrl/api/chat" -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 300
    if ([string]::IsNullOrWhiteSpace($reply.message.content)) { throw 'Model returned no text.' }

    $configPath = Join-Path $projectRoot 'AutoCar.Web/appsettings.Local.json'
    $settings = if(Test-Path -LiteralPath $configPath){Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json}else{[PSCustomObject]@{}}
    # Remove the old paid-provider credentials from this project's local settings.
    $settings | Add-Member -NotePropertyName AI -NotePropertyValue ([PSCustomObject]@{Provider='Ollama';OllamaUrl=$baseUrl;OllamaModel=$Model}) -Force
    [IO.File]::WriteAllText($configPath,($settings|ConvertTo-Json -Depth 32),[Text.UTF8Encoding]::new($false))
    Write-Host ''
    Write-Host 'READY: Free local AI is running. No API key or per-message API fee.' -ForegroundColor Green
    Write-Host 'Restart AutoCar.Web once, open the showroom and use the chat button.'
    Write-Host 'After restarting Windows, double-click Bat-AI-Mien-Phi.cmd to start AI again.'
}
catch {
    Write-Host ('Could not start free AI: '+$_.Exception.Message) -ForegroundColor Red
    Write-Host 'If downloading fails, install Ollama from https://ollama.com/download/windows and run this file again.'
    exit 1
}

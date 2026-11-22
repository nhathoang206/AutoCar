param(
    [string]$Model = 'gpt-5-mini'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot 'AutoCar.Web/appsettings.Local.json'
$apiKey = $env:AI__ApiKey
if ([string]::IsNullOrWhiteSpace($apiKey)) { $apiKey = $env:OPENAI_API_KEY }
if ([string]::IsNullOrWhiteSpace($apiKey) -and (Test-Path -LiteralPath $configPath)) {
    $existingSettings = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $apiKey = $existingSettings.AI.ApiKey
    if (-not $PSBoundParameters.ContainsKey('Model') -and $existingSettings.AI.Model) { $Model = $existingSettings.AI.Model }
    $existingSettings = $null
}
$secret = $null
$secretPointer = [IntPtr]::Zero

try {
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Host 'Create a project API key at https://platform.openai.com/api-keys'
        $secret = Read-Host 'OpenAI API key (hidden input)' -AsSecureString
        $secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
        $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)
    }
    if ([string]::IsNullOrWhiteSpace($apiKey)) { throw 'An API key is required.' }
    $apiKey = $apiKey.Trim()
    Write-Host "Testing a short AI response with model $Model..."
    # A real, small request checks credentials, quota and model access before saving.
    $payload = @{
        model = $Model
        store = $false
        max_output_tokens = 2000
        input = 'Reply with exactly: AutoCar AI connected'
    } | ConvertTo-Json
    try {
        $result = Invoke-RestMethod -Uri 'https://api.openai.com/v1/responses' -Method Post -Headers @{
            Authorization = "Bearer $apiKey"
        } -ContentType 'application/json' -Body $payload -TimeoutSec 90
    }
    catch {
        $status = 0
        if ($null -ne $_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
        $hint = switch ($status) {
            401 { 'API key rejected. Check that it is a valid OpenAI project key.' }
            403 { 'The project does not have permission to use this model.' }
            404 { 'Model unavailable. Pass -Model with a model enabled for your project.' }
            429 { 'API quota or rate limit reached. Check API billing and limits.' }
            default { 'Could not reach OpenAI. Check the network and try again.' }
        }
        throw "AI connection failed (HTTP $status). $hint No configuration saved."
    }
    $texts = @($result.output | Where-Object { $_.type -eq 'message' } | ForEach-Object {
        $_.content | Where-Object { $_.type -eq 'output_text' } | ForEach-Object { $_.text }
    })
    if ([string]::IsNullOrWhiteSpace(($texts -join ''))) { throw 'AI returned no text. No configuration saved.' }

    $settings = [PSCustomObject]@{}
    if (Test-Path -LiteralPath $configPath) {
        $settings = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    if ($null -eq $settings.PSObject.Properties['AI']) {
        $settings | Add-Member -NotePropertyName AI -NotePropertyValue ([PSCustomObject]@{})
    }
    $settings.AI | Add-Member -NotePropertyName ApiKey -NotePropertyValue $apiKey -Force
    $settings.AI | Add-Member -NotePropertyName Provider -NotePropertyValue 'OpenAI' -Force
    $settings.AI | Add-Member -NotePropertyName Model -NotePropertyValue $Model -Force
    $json = $settings | ConvertTo-Json -Depth 32
    [IO.File]::WriteAllText($configPath, $json, [Text.UTF8Encoding]::new($false))
    Write-Host 'Connected. Configuration saved to AutoCar.Web/appsettings.Local.json (ignored by source control).'
    Write-Host 'Restart AutoCar.Web in Development mode, then open the showroom chatbot.'
}
finally {
    if ($secretPointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer) }
    if ($null -ne $secret) { $secret.Dispose() }
    $apiKey = $null
    $json = $null
    $settings = $null
}

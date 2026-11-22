param([string]$Api='http://localhost:5180',[string]$Web='http://localhost:5080')
$ErrorActionPreference='Stop'
$results=@()
function Check-Http([string]$Name,[string]$Url,[int]$Expected,[string]$Method='GET',[string]$Body='') {
    try {
        $request=[System.Net.HttpWebRequest]::Create($Url)
        $request.Method=$Method;$request.AllowAutoRedirect=$false
        if($Body){$bytes=[System.Text.Encoding]::UTF8.GetBytes($Body);$request.ContentType='application/json';$request.ContentLength=$bytes.Length;$stream=$request.GetRequestStream();$stream.Write($bytes,0,$bytes.Length);$stream.Close()}
        $response=$request.GetResponse()
        $actual=[int]$response.StatusCode
        $response.Close()
    } catch {
        $exception=$_.Exception
        while($exception.InnerException -and -not $exception.Response){$exception=$exception.InnerException}
        if($exception.Response){$actual=[int]$exception.Response.StatusCode;$exception.Response.Close()}else{throw}
    }
    $script:results += [pscustomobject]@{Name=$Name;Expected=$Expected;Actual=$actual;Passed=($actual -eq $Expected)}
}
Check-Http 'API process health' "$Api/health" 200
Check-Http 'Swagger document' "$Api/swagger/v1/swagger.json" 200
Check-Http 'Protected orders' "$Api/api/orders" 401
Check-Http 'Protected dashboard' "$Api/api/dashboard/overview" 401
Check-Http 'Anonymous brand creation blocked' "$Api/api/brands" 401 'POST' '{"name":"Blocked"}'
Check-Http 'Invalid registration rejected before database' "$Api/api/auth/register" 400 'POST' '{"email":"invalid","password":"x","fullName":""}'
Check-Http 'Unknown endpoint' "$Api/api/missing" 404
Check-Http 'MVC login page' "$Web/dang-nhap" 200
Check-Http 'MVC register page' "$Web/dang-ky" 200
Check-Http 'MVC about page' "$Web/gioi-thieu" 200
Check-Http 'MVC compare page' "$Web/so-sanh" 200
Check-Http 'MVC contact page' "$Web/lien-he" 200
Check-Http 'MVC admin redirects anonymous' "$Web/admin" 302
Check-Http 'CSRF rejects anonymous gateway mutation' "$Web/gateway/public/contacts" 400 'POST' '{"name":"Test","email":"test@example.com","message":"Test"}'
$results | Format-Table -AutoSize
$reportPath=Join-Path $PSScriptRoot '../docs/SMOKE_RESULTS.json'
$results | ConvertTo-Json | Set-Content -LiteralPath $reportPath -Encoding UTF8
if($results.Passed -contains $false){throw 'Smoke tests failed.'}
Write-Output "$($results.Count) smoke checks passed. SQL CRUD is tested separately."

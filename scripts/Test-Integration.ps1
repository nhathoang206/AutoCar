param([string]$Api='http://localhost:5180',[string]$Web='http://localhost:5080')
$ErrorActionPreference='Stop'
if(-not $env:AUTOCAR_TEST_PASSWORD){throw 'Set AUTOCAR_TEST_PASSWORD to the development seed password. Run only against a development database.'}
$results=[System.Collections.Generic.List[object]]::new()
function Call-Api([string]$Method,[string]$Path,$Body=$null,[string]$Token='',[int]$Expected=200) {
    $args=@{Uri="$Api/api/$Path";Method=$Method;UseBasicParsing=$true;ErrorAction='Stop'}
    if($Token){$args.Headers=@{Authorization="Bearer $Token"}}
    if($null -ne $Body){$args.Body=ConvertTo-Json $Body -Depth 15;$args.ContentType='application/json'}
    $response=$null
    try{$response=Invoke-WebRequest @args;$actual=[int]$response.StatusCode}catch{if($_.Exception.Response){$actual=[int]$_.Exception.Response.StatusCode}else{throw}}
    $results.Add([pscustomobject]@{Test="$Method /api/$Path";Expected=$Expected;Actual=$actual;Passed=($actual -eq $Expected)})
    if($actual -ne $Expected){throw "Expected $Expected, got $actual for $Method $Path"}
    if($response -and $response.Content){return ($response.Content | ConvertFrom-Json)}
}
try {
    $adminPassword=if($env:AUTOCAR_ADMIN_PASSWORD){$env:AUTOCAR_ADMIN_PASSWORD}else{$env:AUTOCAR_TEST_PASSWORD}
    $admin=Call-Api POST 'auth/login' @{email='admin@autocar.local';password=$adminPassword}
    $a=$admin.accessToken
    Call-Api POST 'auth/login' @{email='admin@autocar.local';password='IntentionallyWrong!99'} '' 401 | Out-Null
    $suffix=[guid]::NewGuid().ToString('N').Substring(0,10)
    $customer=Call-Api POST 'auth/register' @{email="qa-$suffix@autocar.local";password=$env:AUTOCAR_TEST_PASSWORD;fullName="QA $suffix";phone='0900000000'} '' 201
    $c=$customer.accessToken
    Call-Api POST 'brands' @{name='Blocked by role'} $c 403 | Out-Null
    Call-Api GET 'cars' | Out-Null
    Call-Api GET 'cars/2147483647' $null '' 404 | Out-Null
    Call-Api POST 'brands' @{name=''} $a 400 | Out-Null
    $brand=Call-Api POST 'brands' @{name="QA $suffix";isActive=$true} $a 201
    Call-Api PUT "brands/$($brand.id)" @{name="QA Updated $suffix";isActive=$true} $a 204 | Out-Null
    Call-Api DELETE "brands/$($brand.id)" $null $a 204 | Out-Null
    Call-Api GET "brands/$($brand.id)" $null '' 404 | Out-Null
    $models=Call-Api GET 'car-models'
    $carData=@{carModelId=$models[0].id;code="QA-$suffix";name='QA transaction car';year=2025;price=500000000;seats=5;fuel='Petrol';transmission='Automatic';bodyStyle='Sedan';stock=1;isVisible=$true;images=@()}
    $car=Call-Api POST 'cars' $carData $a 201
    $carData.name='QA Updated';$carData.rowVersion=$car.rowVersion;$carData.inventoryVersion=$car.inventoryVersion
    Call-Api PUT "cars/$($car.id)" $carData $a 204 | Out-Null
    $fresh=Call-Api GET "cars/$($car.id)"
    if($fresh.name -ne 'QA Updated'){throw 'PUT did not persist.'}
    Call-Api PUT "cars/$($car.id)" $carData $a 409 | Out-Null
    Call-Api POST 'orders' @{carId=$car.id;quantity=2} $c 409 | Out-Null
    $order1=Call-Api POST 'orders' @{carId=$car.id;quantity=1;note="QA $suffix"} $c 201
    $order2=Call-Api POST 'orders' @{carId=$car.id;quantity=1;note="QA $suffix"} $c 201
    Call-Api PUT "orders/$($order1.id)/status" @{status='Completed'} $a 409 | Out-Null
    Call-Api PUT "orders/$($order1.id)/status" @{status='Confirmed'} $a 204 | Out-Null
    Call-Api PUT "orders/$($order2.id)/status" @{status='Confirmed'} $a 409 | Out-Null
    $sold=Call-Api GET "cars/$($car.id)"
    if($sold.stock -ne 0 -or $sold.sold -ne 1){throw 'Inventory did not decrement exactly once.'}
    Call-Api PUT "orders/$($order1.id)/status" @{status='Cancelled'} $a 204 | Out-Null
    $restored=Call-Api GET "cars/$($car.id)"
    if($restored.stock -ne 1 -or $restored.sold -ne 0){throw 'Cancellation did not restore inventory.'}
    $before=Call-Api GET 'dashboard/overview' $null $a
    Call-Api PUT "orders/$($order2.id)/status" @{status='Confirmed'} $a 204 | Out-Null
    Call-Api POST "orders/$($order2.id)/payments" @{amount=500000000;reference="QA-$suffix"} $a 201 | Out-Null
    Call-Api PUT "orders/$($order2.id)/status" @{status='Completed'} $a 204 | Out-Null
    $after=Call-Api GET 'dashboard/overview' $null $a
    if($after.revenue -ne ($before.revenue+500000000)){throw 'Revenue is not consistent with paid completed order.'}
    $raceData=@{carModelId=$models[0].id;code="QA-RACE-$suffix";name='QA simultaneous confirmation';year=2025;price=600000000;seats=5;fuel='Petrol';transmission='Automatic';bodyStyle='SUV';stock=1;isVisible=$true;images=@()}
    $raceCar=Call-Api POST 'cars' $raceData $a 201
    $race1=Call-Api POST 'orders' @{carId=$raceCar.id;quantity=1} $c 201
    $race2=Call-Api POST 'orders' @{carId=$raceCar.id;quantity=1} $c 201
    Add-Type -AssemblyName System.Net.Http
    $http=[System.Net.Http.HttpClient]::new()
    try {
        $requests=@()
        foreach($raceOrder in @($race1,$race2)){
            $request=[System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Put,"$Api/api/orders/$($raceOrder.id)/status")
            $request.Headers.Authorization=[System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer',$a)
            $request.Content=[System.Net.Http.StringContent]::new('{"status":"Confirmed"}',[System.Text.Encoding]::UTF8,'application/json')
            $requests += $request
        }
        $t1=$http.SendAsync($requests[0]);$t2=$http.SendAsync($requests[1])
        [System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]@($t1,$t2))
        $codes=@([int]$t1.Result.StatusCode,[int]$t2.Result.StatusCode) | Sort-Object
        $ok=($codes[0] -eq 204 -and $codes[1] -eq 409)
        $results.Add([pscustomobject]@{Test='Simultaneous confirmation stock1';Expected='204,409';Actual=($codes -join ',');Passed=$ok})
        if(-not $ok){throw 'Concurrent confirmation did not produce one success and one conflict.'}
        $raceStock=Call-Api GET "cars/$($raceCar.id)"
        if($raceStock.stock -ne 0 -or $raceStock.sold -ne 1){throw 'Concurrent confirmation corrupted inventory.'}
        $t1.Result.Dispose();$t2.Result.Dispose();$requests | ForEach-Object {$_.Dispose()}
    } finally {$http.Dispose()}
    foreach($raceOrder in @($race1,$race2)){
        $state=Call-Api GET "orders/$($raceOrder.id)" $null $a
        if($state.status -eq 'Confirmed'){Call-Api PUT "orders/$($raceOrder.id)/status" @{status='Cancelled'} $a 204 | Out-Null}
    }
    Call-Api DELETE "cars/$($raceCar.id)" $null $a 204 | Out-Null
    Call-Api POST 'test-drive-bookings' @{carId=$car.id;scheduledAt=[DateTimeOffset]::UtcNow.AddDays(2).ToString('O');phone='0900000000'} $c 201 | Out-Null
    Call-Api POST 'quote-requests' @{carId=$car.id;phone='0900000000';message='QA quote'} $c 201 | Out-Null
    Call-Api POST 'reviews' @{carId=$car.id;rating=5;comment='QA completed purchase review'} $c 201 | Out-Null
    Call-Api DELETE "cars/$($car.id)" $null $a 204 | Out-Null
    Call-Api GET "cars/$($car.id)" $null '' 404 | Out-Null
    $rotated=Call-Api POST 'auth/refresh' @{refreshToken=$customer.refreshToken}
    Call-Api POST 'auth/refresh' @{refreshToken=$customer.refreshToken} '' 401 | Out-Null
    Call-Api POST 'auth/logout' $null $rotated.accessToken 204 | Out-Null
    Call-Api GET 'auth/me' $null $rotated.accessToken 401 | Out-Null
    $home=Invoke-WebRequest $Web -UseBasicParsing
    if($home.StatusCode -ne 200 -or $home.Content -notmatch 'car-card'){throw 'MVC home is not displaying API cars.'}
    $loginPage=Invoke-WebRequest "$Web/dang-nhap" -UseBasicParsing -SessionVariable mvc
    $anti=[regex]::Match($loginPage.Content,'name="__RequestVerificationToken"[^>]*value="([^"]+)"').Groups[1].Value
    if(-not $anti){throw 'MVC antiforgery token missing.'}
    $loggedIn=Invoke-WebRequest "$Web/dang-nhap" -Method POST -UseBasicParsing -WebSession $mvc -Body @{Email="qa-$suffix@autocar.local";Password=$env:AUTOCAR_TEST_PASSWORD;__RequestVerificationToken=$anti}
    if($loggedIn.Content -notmatch 'account-page'){throw 'MVC cookie login did not reach customer dashboard.'}
    $mvcProfile=Invoke-RestMethod "$Web/gateway/auth/me" -WebSession $mvc
    if($mvcProfile.email -ne "qa-$suffix@autocar.local"){throw 'MVC token vault did not call the API as the signed-in user.'}
    $results.Add([pscustomobject]@{Test='MVC login + server token gateway';Expected=200;Actual=200;Passed=$true})
    Write-Output 'SQL/API/MVC integration scenarios passed. QA records intentionally retained for audit. Restart persistence requires the additional manual check in TEST_CASES.md.'
} finally {
    $results | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $PSScriptRoot '../docs/INTEGRATION_RESULTS.json') -Encoding UTF8
    $results | Format-Table -AutoSize
}

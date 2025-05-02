$AzureDomain = '' # contoso.com
$ClientID = '' # From the steps above
$Secret = '' # From the steps above
$InstanceSubdomain = '' # myinstance (don't include .immy.bot)


#####################
$TokenEndpointUri = [uri](Invoke-RestMethod "https://login.windows.net/$AzureDomain/.well-known/openid-configuration").token_endpoint
$TenantID = ($TokenEndpointUri.Segments | Select-Object -Skip 1 -First 1).Replace("/", "")
$Script:BaseURL = "https://$($InstanceSubdomain).immy.bot"

Function Get-ImmyBotApiAuthToken {
    Param ($TenantId, $ApplicationId, $Secret, $ApiEndpointUri)
    $RequestAccessTokenUri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $body = "grant_type=client_credentials&client_id=$applicationId&client_secret=$Secret&scope=$($Script:BaseURL)/.default"
    $contentType = 'application/x-www-form-urlencoded'
    try {
        $Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType $contentType
        return $Token
    }
    catch { throw }
}
$Token = Get-ImmyBotApiAuthToken -ApplicationId $ClientId -TenantId $TenantID -Secret $Secret -ApiEndpointUri $BaseURL
$Script:ImmyBotApiAuthHeader = @{
    "authorization" = "Bearer $($Token.access_token)"
}

Function Invoke-ImmyBotRestMethod {
    param([string]$Endpoint, [string]$Method, $Body)
    if($body -is [Hashtable])
    {
        $Body = $Body | ConvertTo-Json -Depth 100
    }
    $Endpoint = $Endpoint.TrimStart('/')
    $params = @{}
    if ($Method) {
        $params.method = $Method
    }
    if ($Body) {
        $params.body = $body
    }
    Invoke-RestMethod -Uri "$($Script:BaseURL)/$Endpoint" -Headers $Script:ImmyBotApiAuthHeader -ContentType "application/json" @params
}
$SoftwareList = Invoke-ImmyBotRestMethod -Endpoint "/api/v1/software/global"

$SLJSON = $SoftwareList | ConvertTo-Json
Write-Host $SLJSON
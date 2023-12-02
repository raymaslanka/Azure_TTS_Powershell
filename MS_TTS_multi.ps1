# need to retrieve an access token using your subscription key 
# to later post a request to generate the audio
$subscriptionKey = '<PUT AZURE TTS SUBSCRIPTION KEY HERE>'

$FetchTokenHeader = @{
    'Content-type'='application/x-www-form-urlencoded';
    'Content-Length'= '0';
    'Ocp-Apim-Subscription-Key' = $subscriptionKey
}

$OAuthToken = Invoke-RestMethod -Method POST -Uri https://eastus.api.cognitive.microsoft.com/sts/v1.0/issueToken -Headers $FetchTokenHeader

$accessKey = $OAuthToken
$region = "eastus" 
$endpoint = "https://$region.tts.speech.microsoft.com"

$voiceName = "en-US-JennyNeural"

# we set our 8bit 8khz requirement here
$headers = @{
    "Authorization" = "Bearer: $accessKey"
    "Content-Type" = "application/ssml+xml"
    "User-Agent" = "CrappyTTSScript"
    "X-Microsoft-OutputFormat" = "riff-8khz-8bit-mono-mulaw"
}

$file = "prompts.csv"
$data = Import-Csv $file

foreach ($row in $data) {
    $value1 = $row.Column1
    $value2 = $row.Column2

    $outputFile = "$value1.wav"
    $text = $value2

    $requestBody = @"
    <speak version='1.0' xml:lang='en-US'><voice xml:lang='en-US' name='$voiceName'>$text</voice></speak>
"@

    # Invoke the REST API to generate speech
    Write-Host $endpoint/cognitiveservices/v1
    $response = Invoke-RestMethod -Uri "$endpoint/cognitiveservices/v1" -Headers $headers -Method POST -Body $requestBody -OutFile $outputFile

    Write-Host "Speech synthesis completed. Output file: $outputFile"
}


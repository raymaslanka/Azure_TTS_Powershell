# require a subscription key as a CLI arguement
if ($args[0]) {
    $subscriptionKey = $args[0]
}
else {
    Write-Output ""
    Write-Output "Please pass an Azure subscription key via command line."
    Write-Output "Try: PS $PSscriptRoot> ./$($MyInvocation.MyCommand.Name) <YOUR SUBSCRIPTION KEY>"
    Write-Output ""
    Exit
}


# get an authorization token using the subscription key
$FetchTokenHeader = @{
    'Content-type'='application/x-www-form-urlencoded';
    'Content-Length'= '0';
    'Ocp-Apim-Subscription-Key' = $subscriptionKey
}
Try {
    $OAuthToken = Invoke-RestMethod -Method POST -Uri https://eastus.api.cognitive.microsoft.com/sts/v1.0/issueToken -Headers $FetchTokenHeader
} Catch {
    Write-Host "ERROR: There is a problem getting an authorization token:"
    if($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message
    } else {
        Write-Host $_
    }
    Write-Host "If a token was retrived recently, this may not be fatal."
}


# define your MS region, voicename, file codec
$region = "eastus" 
$endpoint = "https://$region.tts.speech.microsoft.com"
$voiceName = "en-US-JennyNeural"
$headers = @{
    "Authorization" = "Bearer: $OAuthToken"
    "Content-Type" = "application/ssml+xml"
    "User-Agent" = "CrappyTTSScript"
    "X-Microsoft-OutputFormat" = "riff-8khz-8bit-mono-mulaw"
}


# invoke REST API method for each row in CSV
# return a file name defined in column 1 with audio defined in column 2
$file = "prompts.csv"
$data = Import-Csv $file
foreach ($row in $data) {
    $value1 = $row.Column1
    $value2 = $row.Column2
    # file extension here (.wav, .mp3, etc) should match X-Microsoft-OutputFormat above
    $outputFile = "$value1.wav"
    $text = $value2

    $requestBody = @"
    <speak version='1.0' xml:lang='en-US'><voice xml:lang='en-US' name='$voiceName'>$text</voice></speak>
"@
    Try {
        $response = Invoke-RestMethod -Uri "$endpoint/cognitiveservices/v1" -Headers $headers -Method POST -Body $requestBody -OutFile $outputFile
        Write-Host "Speech synthesis completed. See output file: $outputFile"
    } Catch {
        Write-Host "ERROR: There is a problem requesting the file $outputFile :"
        if($_.ErrorDetails.Message) {
            Write-Host $_.ErrorDetails.Message
        } else {
            Write-Host $_
        }
    }
}


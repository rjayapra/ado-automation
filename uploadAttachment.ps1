$user = <user>
$PAT = <Token>

#$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
$header = @{authorization = "Basic $token" }

$org = <Org>
$teamProject = <project>
$wiId = <workitemid>

$folderPath = "c:/temp"
$fileName = "data_1.csv"

$createAttachmetUrlTemplate = "https://dev.azure.com/$org/$teamProject/_apis/wit/attachments?fileName={fileName}&api-version=6.0"
$updateWIUrlTemplate = "https://dev.azure.com/$org/_apis/wit/workitems/{id}?api-version=6.0"

$wiBodyTemplate = '[{"op": "add","path": "/relations/-","value": {"rel": "AttachedFile","url": "{attUrl}", "attributes": {"comment": "Adding file"}}}]'

function InvokePostRequest ($PostUrl, $body)
{   
    #return Invoke-RestMethod -Uri $PostUrl -Method Post -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}  -Body $body
    $body = ConvertTo-Json $body
    Write-Host "Post attachment" #$body
    return Invoke-WebRequest -Uri $PostUrl -Method Post -ContentType "application/json" -Headers $header  -Body $body
}

function InvokePatchRequest ($PatchUrl, $body)
{   
       
    Write-Host "Patching ..."    $body
    #return Invoke-RestMethod -Uri $PatchUrl -Method Patch -ContentType "application/json-patch+json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}  -Body $body
    return Invoke-RestMethod -Uri $PatchUrl -Method Patch -ContentType "application/json-patch+json" -Headers $header  -Body   $body

}

$bytes = [System.IO.File]::ReadAllBytes("$folderPath/$fileName")

$createAttachmetUrl = $createAttachmetUrlTemplate -replace "{filename}", $fileName

$resAtt = InvokePostRequest $createAttachmetUrl $bytes
$resAtt = $resAtt | ConvertFrom-Json
Write-Host "Url: " $resAtt.url

$updateWIUrl = $updateWIUrlTemplate -replace "{id}", $wiId
$wiBody = $wiBodyTemplate -replace "{attUrl}", $resAtt.url
Write-Host "Body :" $wiBody

InvokePatchRequest $updateWIUrl $wiBody 
#Run this command before executing script
#Set-ExecutionPolicy -Scope Process -ExecutionPolicy  ByPass
$PAT=<PATToken>
$org = <orgname>
$orgUrl = "https://dev.azure.com/$($org)/" 
$project=<project>
$queryString = "api-version=6.0"
$user= <username>
$srcPath="C:\Temp\"
$fileextension="*.csv"
$th="`n| Sl.No | Filename | Date |`n|--|--|--|`n"
    

# Create header with PAT
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
$header = @{authorization = "Basic $token" }

# Get the list of all projects in the organization
#$projectsUrl = "$orgUrl/_apis/projects?$queryString"
#$projects = Invoke-RestMethod -Uri $projectsUrl -Method Get -ContentType "application/json" -Headers $header
#$projects.value | ForEach-Object {
  # Write-Host $_.id $_.name
#}

$queryString = "recursionLevel=0&includeContent=true&api-version=6.0"
$wikiProject="BoardsDemoProject.wiki"
$wiki="_apis/wiki/wikis/$wikiProject"
$path="/Azure Sentinel/Boards Overview/Sub Page 2"

#Get the content of page and eTag
$wikiUrl = "$orgUrl/$project/$wiki/pages?path=$path&$queryString"
$wikiDetails = (Invoke-WebRequest -Uri $wikiUrl -Method Get -ContentType "application/json" -Headers $header ) | ConvertFrom-Json
$pagecontent= $wikiDetails.content 
Write-Host ">>>" $pagecontent.trim()


#This is required to update the content of wikipage
$eTag=(Invoke-WebRequest -Uri $wikiUrl -Method Get -ContentType "application/json" -Headers $header ).Headers.ETag
$eTag
$header = @{authorization = "Basic $token" ;
            'If-Match' = $eTag}

#Clone Wiki and upload folders
Remove-Item -Path ./$wikiProject -Force -Recurse
git clone https://$user@dev.azure.com/$org/$project/_git/$wikiProject
cd $wikiProject

#Check if the file is present in Wiki, if not upload file
$infiles=Get-ChildItem -Path $srcPath\$fileextension | Select-Object -ExpandProperty Name
$newFiles = New-Object System.Collections.ArrayList
$infiles | ForEach-Object {
    $filename=$_ 
    Write-Host "Checking $filename ... "
    If (-not(Test-Path -Path  .attachments/$filename)) {
        Copy-Item -Path $srcPath\$filename -Destination .attachments/
        $newFiles.Add("$filename")        
    }    
}
Write-Host "Files Added" $newFiles


#Update the page
$wikiUpdateUrl = "$orgUrl/$project/$wiki/pages/20?api-version=6.0-preview.1"
$body=$pagecontent
if ( $newFiles) {
    # Commit the files to wiki project
    Write-Host "Committing files"
    git status
    git add .attachments/*
    git commit -m "Added new attachments"
    git push -u origin


    $date=Get-Date
    $body=$body+$th
    $newFiles | ForEach-Object {
        $row="|# | [$_](.attachments/$_)| $date |`n"    
        $body=$body+$row
    }
    
    $body= $body | ConvertTo-Json  
    $body= "{""content"" : $body }"
   
    $body
    $wikiUpdateUrl
    $header 
    $update = Invoke-WebRequest -Uri $wikiUpdateUrl -Method PATCH -ContentType "application/json" -Headers $header -Body $body 
    Write-Host $update.content -ForegroundColor Yellow 
    
}
else {
    Write-Host "!!!!!!!  No new files to upload"
}
cd ..
exit(0)


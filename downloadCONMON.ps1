
$FilePath = "C:\Temp\CONMONUPDATES" + (Get-Date -UFormat %b) + (Get-Date -UFormat %Y)

If(-Not (Test-Path $FilePath)){
    mkdir $FilePath
}

#Get-AdobeReaderEXE
$VersionURI = "https://rdc.adobe.io/reader/products?lang=en&site=enterprise&os=Windows 10&api_key=dc-get-adobereader-cdn"
$Version = (Invoke-RestMethod -Uri $VersionURI).Products.Reader.Version 
$RDRVersion = ($Version -replace '\.',$Null).Trim()
Write-host "Latest version of AdobeReader is: $RDRVersion" -ForegroundColor Green
$DownloadURI = ('http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/{0}/AcroRdrDC{0}_en_US.exe' -f $RDRVersion)
Invoke-WebRequest -uri $DownloadURI -OutFile ("$FilePath\AcroRdrDC" + $RDRVersion + "_en_US.exe")

#Get-AdobeAcrobat



#Get-FirefoxESR

# Specify the URL Source for Firefox.
$FireFoxSourceURI = "https://download.mozilla.org/?product=firefox-esr-latest&lang=en-US"

# Specify the location to cache the download
$DownloadLocation = "$FilePath\Firefox Setup esr.exe"

#Define a list of processes to stop

# Retrieve the file
Write-host "Retrieving download from $FireFoxSourceURI"
write-host "Downloading file to $DownloadLocation"
Invoke-WebRequest -uri $FireFoxSourceURI -Outfile "$DownloadLocation"






#Get-Java


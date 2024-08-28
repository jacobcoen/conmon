Import-Module -Name ActiveDirectory
cd "C:\Java\"
$javeSource32 = "jre1.8.0_221.msi"
$javaSource64 = "jre1.8.0_22164.msi"

$credential = Get-Credential

$computers = Get-ADComputer -Identity *


foreach ($computer in $computers){
Invoke-Command -ComputerName $computer -ScriptBlock{
  $javaDestination = "\\$computer\C:\Java\"
  $java = Get-WmiObject -class win32_product | Where-Object {$_.Name -match "Java"}
  if($java -eq $null)
  {
    Copy-Item -ComputerName $computer -Path $javaSource32,$javaSource64 -Destination $javaDestination
  Write-Host "No instance of java is installed. Installing Java..." -ForegroundColor Green
 $installJava32 =  Start-Process "$javaDestination\$javaSource32"
 $installJava32.WaitForExit()
  Write-Host "32 Bit version of Java is installed"
 $installJava64 =  Start-Process "$javaDestination\$javaSource64"
 $installJava64.WaitForExit()
  Write-Host "64 bit version of java is installed"
  Write-Host "JAVA IS INSTALLED" -ForegroundColor Magenta
  }
  else{
  Write-Host "UNINSTALLING JAVA `n----------------- `n `n" -ForegroundColor Green
  $java.Uninstall() | Out-Null
  Write-Host "JAVA IS UNINSTALLED`n"
  Write-Host "REINSTALLING JAVA `n----------------- `n `n `n" -ForegroundColor Green
  Copy-Item -ComputerName $computer -Path $newjavaLocation32,$newjavalocation64 -Destination "\\$computer\C:\Java\"
  $installJava32 =  Start-Process "$javaDestination\$javaSource32"
  $installJava32.WaitForExit()
   Write-Host "32 Bit version of Java is installed"
  $installJava64 =  Start-Process "$javaDestination\$javaSource64"
  $installJava64.WaitForExit()
  Write-Host "64 bit version of java is installed `n `n `n"
  Write-Host "JAVA IS INSTALLED" -ForegroundColor Magenta
  }
}
}
  #Add remote uninstall and installations through domain systems
  #Adobe with the same things
$masterLog = "C:\Temp\ConmonLogFile.csv"
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
 
    [pscustomobject]@{
        Time = (Get-Date -f g)
		Host = $env:COMPUTERNAME
        Message = $Message
        Severity = $Severity
    } | Export-Csv -Path $masterLog -Append -NoTypeInformation
 }


 try {
	$workstations = Get-ADComputer -Filter *  | Select-Object -ExpandProperty Name
	}
	catch [System.Security.Authentication.AuthenticationException] {
	$message = $_
	Write-Log -Message "Unable to connect to the domain to capture domain computer information. $message" -Severity Error
	}
	catch {
	$message = $_
	Write-Log -Message "Unable to connect to the domain to capture domain computer information. $message" -Severity Error
	}

function Find-Installed{
	$csv = ".\softwares\pkgs.csv"
	Write-Log -Message "$csv set to use as default for SW and switches." -Severity Information
    foreach ($workstation in $workstations)
    {
		Write-Host "$workstation" -ForegroundColor red
        #Create temp directory on each computer
        if(-not (Test-Path("\\$workstation\c$\Temp\"))){
			mkdir "\\$workstation\c$\Temp\softwares" -Force
			Write-host "C:\Temp Directory does not exist on $workstation. Creating Directory." -ForegroundColor Yellow
		}
		
        if ($workstation -eq $env:computername){
			
			try{
				Copy-Item "$csv" "C:\Temp\softwares\" -Force
				Write-Log -Message "Copying $csv to C:\Temp\softwares on $workstation." -Severity Information
			}
		    catch{
				Write-Log -Message "Unable to copy $csv to C:\Temp\softwares on $workstation." -Severity Error
			}
    
    }
        else {
			try {
					Copy-Item "$csv" "\\$workstation\c$\Temp\softwares\" -Force
					Write-Log -Message "Copying $csv to C:\Temp\softwares on $workstation." -Severity Information
				}
			catch{
					$message = $_
					Write-Log -Message "Unable to copy $csv to C:\Temp\softwares on $workstation. $message" -Severity Error
				 }
			}		

    if ($workstation -ne $env:computername)
	{
		Invoke-Command -ComputerName $workstation -ScriptBlock {
			$masterLog = "C:\Temp\ConmonLogFile.csv"
			function Write-Log {
				[CmdletBinding()]
				param(
					[Parameter()]
					[ValidateNotNullOrEmpty()]
					[string]$Message,
			 
					[Parameter()]
					[ValidateNotNullOrEmpty()]
					[ValidateSet('Information','Warning','Error')]
					[string]$Severity = 'Information'
				)
			 
				[pscustomobject]@{
					Time = (Get-Date -f g)
					Host = $env:COMPUTERNAME
					Message = $Message
					Severity = $Severity
				} | Export-Csv -Path $masterLog -Append -NoTypeInformation
			 }
			


		Write-Host "Working on $workstation" -ForegroundColor Green
        $remotepath = "C:\Temp\softwares\"
        $softwares = Import-Csv "$remotepath\pkgs.csv" -Delimiter "," -Header 'Installer', 'Switch', 'Path' | Select-Object -Property Installer, Switch, Path
            foreach ($software in $softwares)
            {
            $softpath = $software.Path
            $softpath = $softpath.ToString()
             $installed = Test-Path($softpath)
                if($installed){
                Add-Content C:\Temp\installed.txt $software.Installer
                Write-Log -Message "Checking:$softpath IS installed on $env:computername" -Severity Information
				}

				####################################################################TEST TAKE OUT########################################
				if(-not $installed){
                    Add-Content C:\Temp\notinstalled.txt $software.Installer
                    Write-Log -Message "Checking:$softpath is NOT installed on $env:computername" -Severity Information
					}
				##################################################END TEST TAKE OUT##################################	
            }
        } -ArgumentList $workstation | Export-Csv -Path $masterLog -Append -NoTypeInformation
    }
    else{
        $remotepath = "C:\Temp\softwares\"
        $softwares = Import-Csv "$remotepath\pkgs.csv" -Delimiter "," -Header 'Installer', 'Switch', 'Path' | Select-Object -Property Installer, Switch, Path
            foreach ($software in $softwares)
            {
            $softpath = $software.Path
            $softpath = $softpath.ToString()
            #Write-Host $softpath###############################TEST TAKE OUT#####################
             $installed = Test-Path($softpath)
                if($installed){
                Add-Content C:\temp\installed.txt $software.Installer
                Write-Log -Message "Checking:$softpath IS installed on $env:computername" -Severity Information
                }
                ####################################################################TEST TAKE OUT########################################
				if(-not $installed){
                    Add-Content C:\Temp\notinstalled.txt $software.Installer
                    Write-Log -Message "Checking:$softpath is NOT installed on $env:computername" -Severity Information
					}
				##################################################END TEST TAKE OUT##################################	 
            }
    	}	
	}
}


function Copy-Software{
	$sourceSoftware = '.\softwares\'
	foreach ($workstation in $workstations)
	{
		$file_list = Get-Content "\\$workstation\C$\Temp\installed.txt"
		$destination = "\\$workstation\c$\Temp\softwares\"
		foreach ($file in $file_list)
			{
				$source = $sourceSoftware + "\$file"
                Copy-Item $source $destination
				Write-Log -Message "Copying $source to $destination" -Severity Information
			}
	}
}


Write-Host "Running function Find-Installed"
Find-Installed
Write-Host "Running function Copy-Software"
Copy-Software
Write-Host "Running function Install-Software"
#Install-Software

function Install-Software
{
	$remotepath = "C:\Temp\softwares\"
	$softwares = Import-Csv "$remotepath\pkgs.csv" -Delimiter "," -Header 'Installer', 'Switch', 'Path' | Select-Object Installer,Switch,Path
	
	foreach ($software in $softwares)
	{
        $softexec = $software.Installer
        Write-Host $softexec -ForegroundColor Blue
		$softexec = $softexec.ToString()
		$pkgs = Get-ChildItem $remotepath$softexec | Where-Object -propert Installer -NE 'pkgs.csv'

		foreach ($pkg in $pkgs)
		{
            Write-Host $pkg -ForegroundColor Magenta
			$ext = [System.IO.Path]::GetExtension($pkg)
			$ext = $ext.ToLower()
			
			$switch = $software.Switch
			$switch = $switch.ToString()
			
			if ($ext -eq ".msi")
			{
				try
				{
					$switch = $software.Switch
					$switch = $switch.ToString()
					Write-Log -Message "Installing $pkg silently with Switch $switch , please wait..." -Severity Information
					Start-Process "$remotepath\$softexec" -ArgumentList "$switch" -Wait
					Remove-Item "$remotepath\$softexec" -Recurse -Force
					Write-Log -Message "Installation of $pkg completed" -Severity Information
				}
				catch
				{
					$message = $_
					Write-Log -Message "Something Happened when trying to install software $softexec with parameters $switch! $message" -Severity Error
				}
				
			}
			else
			{
				try
				{
					#changed $pkg to $softexec below. Revert if needed
					Write-Log -Message "Installing $softexec silently with Switch $switch , please wait..." -Severity Information
					Start-Process "$remotepath\$softexec" -ArgumentList "$switch" -Wait -NoNewWindow
					Remove-Item "$remotepath\$softexec" -Recurse -Force
					Write-Log -Message "Installation of $softexec completed" -Severity Information
				}
				catch
				{
					$message = $_
					Write-Log -Message "Something Happened when trying to install software $softexec with parameters $switch! $message" -Severity Error
				}
			}
		}
	}
}

foreach ($workstation in $workstations)
{
	if ($workstation -ne $env:computername)
	{
		Invoke-Command -ComputerName $workstation -ScriptBlock Function:Install-Software
	}
	else
	{
		Install-Software
	}
}



#Pull all computers from the domain#

try {
	$workstations = Get-ADComputer -Filter *  | Select-Object -ExpandProperty Name
	}
	catch [System.Security.Authentication.AuthenticationException] {
	$message = $_
	Write-Host  "Unable to connect to the domain to capture domain computer information. $message" -ForegroundColor red
    }
	catch {
	$message = $_
	Write-Host  "Unable to connect to the domain to capture domain computer information. $message" -ForegroundColor red
	}



function Find-Installed{
	$csv = ".\softwares\pkgs.csv"
	Write-Host "$csv" -ForegroundColor Red
    foreach ($workstation in $workstations)
    {
		Write-Host "$workstation" -ForegroundColor red
        #Create temp directory on each computer
        if(-not (Test-Path("\\$workstation\c$\Temp\"))){
			mkdir "\\$workstation\c$\Temp\softwares" -Force
			Write-host "C:\Temp Directory does not exist on $workstation. Creating Directory." -ForegroundColor Yellow
		}
		else{
			#Cleanup old files in C:\Temp
			Get-ChildItem -Path "\\$workstation\c$\Temp\" -Include *.* -File -Recurse | foreach { $_.Delete()} -Verbose
            Write-host "CLeaning up old files on $workstation." -ForegroundColor Yellow
		}
		
        if ($workstation -eq $env:computername){
            Write-Host "Copying $csv to C:\Temp\softwares on $workstation." -ForegroundColor Green
            Copy-Item "$csv" "C:\Temp\softwares\" -Force
    
    }
        else {Write-Host "Copying $csv to C:\Temp\softwares on $workstation." -ForegroundColor Green
        Copy-Item "$csv" "\\$workstation\c$\Temp\softwares\" -Force}

    if ($workstation -ne $env:computername)
	{
		Invoke-Command -ComputerName $workstation -ScriptBlock {
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
                	Write-Host "Checking:$softpath installed on $env:computername" -ForegroundColor Green
				}
            }
        }
    }
    else{
        $remotepath = "C:\Temp\softwares\"
        $softwares = Import-Csv "$remotepath\pkgs.csv" -Delimiter "," -Header 'Installer', 'Switch', 'Path' | Select-Object -Property Installer, Switch, Path
            foreach ($software in $softwares)
            {
            $softpath = $software.Path
            $softpath = $softpath.ToString()
             $installed = Test-Path($softpath)
                if($installed){
                	Add-Content C:\temp\installed.txt $software.Installer
                	Write-Host "Checking:$softpath installed on $env:computername" -ForegroundColor Green
                }
                
            }
    }
}
}


function Copy-Software{
	$sourceSoftware = '.\softwares\'
	foreach ($workstation in $workstations)
	{
		try
		{
			$file_list = Get-Content "\\$workstation\C$\Temp\installed.txt"
		}
		catch
		{
			Write-host "The installed.txt file doesn't exist. This is most likely because the workstation $workstation doesn't have and installed software that matches."-ForegroundColor Red
		}
		$destination = "\\$workstation\c$\Temp\softwares\"
		foreach ($file in $file_list)
			{
				$source = $sourceSoftware + "\$file"
                Copy-Item $source $destination
                Write-Host "Copying $source to $destination" -ForegroundColor Yellow
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
        #Write-Host $softexec -ForegroundColor Blue
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
					Write-Host "Installing $pkg silently with Switch $switch , please wait..." -ForegroundColor Yellow
					Start-Process "$remotepath\$softexec" -ArgumentList "$switch" -Wait
					Remove-Item "$remotepath\$softexec" -Recurse -Force
					Write-Host "Installation of $pkg completed" -ForegroundColor Green
				}
				catch
				{
					$message = $_
					Write-Warning "Something Happened on line 56! $message"
				}
				
			}
			else
			{
				try
				{
					Start-Process "$remotepath\$softexec" -ArgumentList "$switch" -Wait -NoNewWindow
					Remove-Item "$remotepath\$softexec" -Recurse -Force
					Write-Host "Installation of $softexec completed" -ForegroundColor Green
				}
				catch
				{
					$message = $_
					Write-Warning "Something Happened on Line 73! $message"
				}
			}
		}
	}
}
$path = ".\softwares\"

foreach ($workstation in $workstations)
{

	if ($workstation -ne $env:computername)
	{
		Invoke-Command -ComputerName $workstation -ScriptBlock {
			function Install-Software
			{
				$remotepath = "C:\Temp\softwares\"
				$softwares = Import-Csv "$remotepath\pkgs.csv" -Delimiter "," -Header 'Installer', 'Switch', 'Path' | Select-Object Installer, Switch, Path
				
				foreach ($software in $softwares)
				{
					$softexec = $software.Installer
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
								Write-Host "Installing $pkg silently with Switch $switch , please wait..." -ForegroundColor Yellow
								Start-Process "$remotepath\$softexec" -ArgumentList "$switch" -Wait
								Remove-Item "$remotepath\$softexec" -Recurse -Force
								Write-Host "Installation of $softexec completed" -ForegroundColor Green
							}
							catch
							{
								$message = $_
								Write-Warning "Something Happened on line 56! $message"
							}
							
						}
						else
						{
							try
							{
								mkdir $remotepath -Force
								Start-Process "$remotepath\$softexec" -ArgumentList "$switch" -Wait -NoNewWindow
								Remove-Item "$remotepath\$softexec" -Recurse -Force
								Write-Host "Installation of $pkg completed" -ForegroundColor Green
							}
							catch
							{
								$message = $_
								Write-Warning "Something Happened on Line 73! $message"
							}
						}
					}
				}
			}
			Install-Software
		}
	}
	else
	{
		Install-Software
	}
}



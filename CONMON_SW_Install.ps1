

<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.175
	 Created on:   	6/14/2022 8:25 AM
	 Created by:   	Jacob Coen
	 Organization: S2CD	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>



function Install-Software
{
	$remotepath = "\Temp\softwares\"
	$softwares = Import-Csv "$remotepath\pkgs.csv" -Delimiter "," -Header 'Installer', 'Switch', 'Path' | Select-Object Installer, Switch, Path
	
	foreach ($software in $softwares)
	{
		$softexec = $software.Installer
		$softexec = $softexec.ToString()
		
		$pkgs = Get-ChildItem $remotepath$softexec | Where-Object { $_.Name -eq $softexec }
		
		foreach ($pkg in $pkgs)
		{
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
					Write-Host "Installing $softexec silently with Switch $switch , please wait..." -ForegroundColor Yellow
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
$wokstations = Get-ADComputer -Filter 'operatingsystem -notlike "*server*" -and enabled -eq "true"' ` -Properties * | Select-Object -ExpandProperty Name
$path = ".\softwares\"

foreach ($workstation in $wokstations)
{
	mkdir "\\$workstation\c$\Temp\" -Force
	Copy-Item "$path" -Recurse "\\$workstation\c$\Temp\" -Force
	
	if ($workstation -ne $env:computername)
	{
		Invoke-Command -ComputerName $workstation -ScriptBlock {
			function Install-Software
			{
				$remotepath = "\Temp\softwares\"
				$softwares = Import-Csv "$remotepath\pkgs.csv" -Delimiter "," -Header 'Installer', 'Switch' | Select-Object Installer, Switch
				
				foreach ($software in $softwares)
				{
					$softexec = $software.Installer
					$softexec = $softexec.ToString()
					
					$pkgs = Get-ChildItem $remotepath$softexec | Where-Object { $_.Name -eq $softexec }
					
					foreach ($pkg in $pkgs)
					{
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
								Write-Host "Installing $softexec silently with Switch $switch , please wait..." -ForegroundColor Yellow
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
			Install-Software
		}
	}
	else
	{
		Install-Software
	}
}
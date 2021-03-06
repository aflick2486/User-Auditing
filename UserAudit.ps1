# Windows User Audit Script
# Written by Adam Flickema
# github.com/aflick2486
# aflickem@emich.edu

function Get-LocalUsers
{
	#Get all local users
   	$users = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='True'" | select -expandproperty name
    	#Get all local users sid's
    	$sid = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='True'" | select -expandproperty SID
    	#Computer name
    	$adsi = [ADSI]"WinNT://$env:computername"

    	#counter
	$x = 0
	Write-Host $users
	Write-Host

    	foreach ($i in $users) #Go through each user 1 by 1
    	{
       		#Write out the user and their sid
	   	$adsiUser = [ADSI]"WinNT://$env:computername/$i"
	   	Write-Host $i 
	   	Write-Host $sid[$x]
	
       		#Ask whether change pass, remove, or skip
	   	Write-Host "What would you like to do?"
	   	$answer = Read-Host -Prompt "[R]emove [C]hange Password [S]kip: "
	   	$answer = $answer.ToLower()
	
	   	If ($answer -eq 'r')
	   	{
		  	$adsi.Delete('User', $i ) #Use computername.delete to remove user
	   	}
	   	ElseIf ($answer -eq 'c')
	   	{
		  	$pass = Read-Host -Prompt "Please enter the password: " -AsSecureString #Ask for a password
		  	#Create password as secure string
          		$BSTR = [system.runtime.interopservices.marshal]::SecureStringToBSTR($pass)
		 	$_pass = [system.runtime.interopservices.marshal]::PtrToStringAuto($BSTR)
		 	#Set the users new password
          		$adsiUser.SetPassword(($_pass))
		  	$adsiUser.SetInfo()
		  	#Free up variables
          		[runtime.interopservices.marshal]::ZeroFreeBSTR($BSTR)
		  	Remove-Variable pass,BSTR,_pass
	   	}
	   	ElseIf ($answer -eq 's')
	  	{
       		}
	#Go to next user for sid
       	$x++
	}
}

function Get-DomainUsers
{
	$users = Get-ADUser -Filter *
	foreach ($i in $users)
	{
		Write-Host $i
		$sid = Get-ADUser -Identity $i | select -expandedproperty SID
		Write-Host $sid
		
		Write-Host "What would you like to do?"
		$answer = Read-Host -Prompt "[R]emove, [C]hange Password, [S]kip: "
		$answer = $answer.ToLower()
		
		If ($answer -eq 'r')
		{
			Remove-ADUser -Identity $i -Confirm
		}
		ElseIf ($answer -eq 'c')
		{
			$pass = Read-Host -Prompt "Please enter the password: " -AsSecureString
			Set-ADAccountPassword -Identity $i -NewPassword $pass
		}
		ElseIf ($answer = 's')
		{
		}
	}
}
while ($true)
{
	$choice = Read-Host -Prompt "Audit [L]ocal or [D]omain Users or [Q]uit: "
	$choice = $choice.ToLower()

	If ($choice -eq 'l')
	{
		Get-LocalUsers
	}
	ElseIf ($choice -eq 'd')
	{
		Get-DomainUsers
	}
	ElseIf ($choice -eq 'q')
	{
		break
	}
}

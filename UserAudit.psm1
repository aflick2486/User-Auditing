# Windows User Audit Script
# Written by Adam Flickema
# github.com/aflick2486
# aflickem@emich.edu

#To Do:
# 1. New fucntion for Add-LocalUser
# 2. New function for Add-LocalGroupUser
# 3. New function for Remove-LocalGroup
# 4. Add comment-help to all functions
# 5. Add parameters to all functions

function New-LocalGroup
{
<#
    .Description
    Creates a new local group on the computer
    
    .Parameter Adsi
    Creates automatic variable for the computer path
    
    .Paramater Group
    Group name to be created (is required)
    
    .Parameter Description
    Description of the group (is required)
    
    .Example
    New-LocalGroup -Group 'Hello' -Description 'This is a test'
#>    
    param(
        [string]$adsi = [ADSI]"WinNT://$env:computername",
        [Parameter(Mandatory=$true)]
        [string]$group,
        [Parameter(Mandatory=$true)]
        [string]$description
    )
    #$adsi = [ADSI]"WinNT://$env:computername"
    #$group = Read-Host -Prompt "What would you like the group to be called?: "
    $makegroup = $adsi.Create('Group', $group)
    $makegroup.SetInfo()
    #$desc = Read-Host -Prompt "Enter description of the group: "
    $makegroup.Description = $desc
    $makegroup.SetInfo()
}

function Edit-LocalUsers
{
<#
    .Description
    This function allows an administrator to check all user accounts and choose to Remove them or Change their password
    
    .Example
    #Only there are no parameters
    Edit-LocalUsers
#>
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

function Edit-DomainUsers
{
<#
    .Description
    Allows admin to check all Active DIrectory Users in current domain and Remove them or Change their password
    
    .Example
    #Only one
    Edit-DomainUsers
#>

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

Export-ModuleMember -function Edit-LocalUsers
Export-ModuleMember -function Edit-DomainUsers
Export-ModuleMember -Function New-LocalGroup

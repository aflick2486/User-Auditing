#!/bin/sh

# Linux User Account Audit Script
# Written by Adam Flickema
# github.com/aflick2486
# aflickem@emich.edu

# Reference
# github.com/ppil/nix-user-audit


readUsers() {
	if [ -e /etc/shadow ]; then 	#Check if /etc/shadow exists and use as file
		file="/etc/shadow"
	else				#Otherwise use /etc/passwd	
		file="/etc/passwd"
	fi

	while read line; do
		checkUsers "$line"	#Take eahc line and send it to checkUsers
	done < "$file"
}

checkUsers() {
	case $line in "#"*) return;; esac			#If line begins with '#' skip this line

	user="$(echo "$line" | cut -s -d: -f 1)"		#Cut the username string
	password="$(echo "$line" | cut -s -d: -f 2)"		#Cut the password string
	

	if [ "$pass" == "" ] || [ "$pass" == "NP" ]; then	#Check for No password line
		printf "%s has a blank password..\n" "$user"
	fi

	choices "$user"						#Send username to choices

}

choices() {
	userPWD="$(grep ^${1}: /etc/passwd)"			#Grab the PWD of each user
	userShell="$(echo $userPWD | cut -s -d ":" -f 7)"	#Cut whether or not they have a shell

	if [ "${$userShell##*/}	!= "nologin" ] && [ "${userShell##*/}" != "false" ]; then
		if [! -e "$userShell" ] || [ -e /etc/shells ] && [ ! "$(grep "^$userShell$" /etc/shells 2>/dev/null)" ]; then
			return	#If no shell skip the user
		fi

		read "
		1. Change Password
		2. Remove
		3. Skip: " $choice

		case $choice in
			1 ) #Change Password 
			passwd $1 < /dev/tty ;;
	
			2 ) #Delete User
			#Determine which command is on the system
			if [ -e "$(which userdel 2>/dev/null)" ]; then
				userdel -r $1
			elif [ -e "$(which deluser 2>/dev/null)" ]; then
				deluser --remove-home $1
			elif [ -e "$(which pw 2>/dev/null)" ]; then
				pw userdel -r $1
			fi;;
			
			3 ) #Skip
			;;
		esac
	fi
	return
}

readUsers()
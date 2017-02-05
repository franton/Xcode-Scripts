#!/bin/bash

# Script to install specific Xcode simulators
# Author: richard at richard - purves dot com
# Version: 1.0 - 4th February 2017

# xcode-installer curtesy of https://github.com/KrauseFx/xcode-install/
# Without that, terminal notifier and cocoaDialog this script wouldn't be possible.

# Set up variables and functions here
consoleuser="$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')"
brandid="com.application.id"
tn="/path/to/terminal-notifier.app/Contents/MacOS/terminal-notifier"
cd="/path/to/cocoaDialog.app/Contents/MacOS/cocoaDialog"

# Logging stuff starts here
LOGFOLDER="/private/var/log/"
LOG=$LOGFOLDER"XcodeSimulators.log"

if [ ! -d "$LOGFOLDER" ];
then
	mkdir $LOGFOLDER
fi

function logme()
{
# Check to see if function has been called correctly
	if [ -z "$1" ]
	then
		echo $( date )" - logme function call error: no text passed to function! Please recheck code!"
		echo $( date )" - logme function call error: no text passed to function! Please recheck code!" >> $LOG
		exit 1
	fi

# Log the passed details
	echo -e $( date )" - $1" >> $LOG
	echo -e $( date )" - $1"
}

# Check and start logging - done twice for local log and for JAMF
logme "Xcode Simulator Installation"

# Log the current console user
logme "Current user: $consoleuser"

# Is Xcode actually installed?
if [ ! -d "/Applications/Xcode.app" ];
then
    su -l "$consoleuser" -c " "'"'$tn'"'" -sender "'"'$brandid'"'" -title "'"Xcode Install"'" -message "'"Xcode not present. Please install."'" "
    logme "Xcode is not present. Stopping."
    exit 0
fi

# Set IFS as we mean to go on, so the space line splitting doesn't occur.
OIFS=$IFS
IFS=$'\n'

# Let's start here by caffinating the mac so it stays awake or bad things happen.
caffeinate -d -i -m -u &
caffeinatepid=$!
logme "Caffinating the mac under process id: $caffeinatepid"

# Is xcode-install installed?
if [ ! -f "/usr/local/bin/xcversion" ];
then
        # Install xcode-install so we can deal with simulators and documentation
        su -l "$consoleuser" -c " "'"'$tn'"'" -sender "'"'$brandid'"'" -title "'"Xcode Install"'" -message "'"Installing missing helper tools"'" "
        logme "Installing missing helper tools."
        curl -sL -O https://github.com/neonichu/ruby-domain_name/releases/download/v0.5.99999999/domain_name-0.5.99999999.gem 2>&1 | tee -a ${LOG}
        sleep 3
        gem install domain_name-0.5.99999999.gem | tee -a ${LOG}
        sleep 3
        gem install --conservative xcode-install | tee -a ${LOG}
        sleep 3
        rm -f domain_name-0.5.99999999.gem | tee -a ${LOG}
fi

# Clean up anything already cached
logme "Cleaning up any previously cached downloads"
/usr/local/bin/xcversion cleanup | tee -a ${LOG}

# Start the installation here
su -l "$consoleuser" -c " "'"'$tn'"'" -sender "'"'$brandid'"'" -title "'"Xcode Install"'" -message "'"Getting available simulators"'" "
logme "Getting available simulators"

# Declare the not installed array
declare -a not_installed

# Read through the output of xcversion, skipping the first line. Look for "not installed".
# If so, add them to the array.
logme "Processing not installed simulators into an array"
while read line;
do
	if [[ ${line} =~ '(not installed)' ]];
	then
		not_installed+=( "${line/' (not installed)'/}" )
		logme "Adding to checkbox list: $line"
	fi
done < <( /usr/local/bin/xcversion simulators | awk 'NR>1' )

# Display list of simulators that aren't installed
# Ask for which ones to install
dialog=$($cd checkbox 	--title "Xcode Simulators" \
			--text "Please choose:" \
			--button1 "Install" \
			--items $(for (( i=0; i<${#not_installed[@]}; i++ )); do echo "${not_installed[$i]}" ; done) )

# Strip the first element from the dialog return, as we don't need it. It refers to the output from clicking the install button.
# Should we test for cancel? Maybe a later version.
dialog=$( echo $dialog | cut -c2- )

# Declare choice array and read dialog choices into it
IFS=' ' read -r -a choices <<< "$dialog"

# Compare the number of not installed to that pulled from the cocoadialog dialog variable
[ ${#not_installed[*]} != ${#choices[*]} ] && { logme "Arrays are different sizes"; exit 1; }

# Do the comparison. If 1, it means it's selected and should be added to the install_me array
# Now we're creating this install_me array so we can be sure it's blank. Otherwise the code gets REALLY messy.

# Declare the install_me array
declare -a install_me

for (( i=0; i<${#choices[@]}; i++ ));
do
	logme "Processing ${not_installed[$i]}"
	if [ "${choices[$i]}" == "1" ]
	then
		logme "Adding ${not_installed[$i]} to install list"
		install_me+=( ${not_installed[$i]} )
	fi
done

# Go through the list, get xcode-install to download and install each one that's missing and specified.
for sim in "${install_me[@]}"
do
	logme "Installing $sim"
	su -l "$consoleuser" -c " "'"'$tn'"'" -sender "'"'$brandid'"'" -title "'"Xcode Install"'" -message "'"Installing '$sim'"'" "
	/usr/local/bin/xcversion simulators --install="$sim" 2>&1 | tee -a ${LOG}
done

# IFS back to normal please.
IFS=$OIFS

# Notify user that all is completed
logme "Installations complete"
su -l "$consoleuser" -c " "'"'$tn'"'" -sender "'"'$brandid'"'" -title "'"Xcode Install"'" -message "'"Installations complete"'" "

# No more caffeine please. I've a headache. Especially after all that array comparison work.
kill "$caffeinatepid"

# All done!
exit 0

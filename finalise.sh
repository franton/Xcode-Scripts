#!/bin/bash

# Xcode finalisation script

# Lots of code curtesy of the Munki wiki pages: https://github.com/munki/munki/wiki/Xcode

# Set up variables and functions here
consoleuser="$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')"
brandid="com.application.id"
tn="/path/to/terminal-notifier.app/Contents/MacOS/terminal-notifier"

# Let's start here by caffinating the mac so it stays awake or bad things happen.
caffeinate -d -i -m -u &
caffeinatepid=$!

# Notify the user that things are happening
su -l "$consoleuser" -c " "'"'$tn'"'" -sender "'"'$brandid'"'" -title "'"Xcode Install"'" -message "'"Starting Xcode finalisation"'" "
sleep 3

# make sure all users on this machine are members of the _developer group
/usr/sbin/dseditgroup -o edit -a everyone -t group _developer

# enable developer mode
/usr/sbin/DevToolsSecurity -enable

# accept Xcode license
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -license accept

# install embedded packages
for PKG in /Applications/Xcode.app/Contents/Resources/Packages/*.pkg
do
	name=$( echo $PKG | cut -c53- )
	su -l "$consoleuser" -c " "'"'$tn'"'" -sender "'"'$brandid'"'" -title "'"Xcode Install"'" -message "'"Installing '$name'"'" "
    /usr/sbin/installer -pkg "$PKG" -target /
done

# disable version check for MobileDeviceDevelopment
/usr/bin/defaults write /Library/Preferences/com.apple.dt.Xcode DVTSkipMobileDeviceFrameworkVersionChecking -bool true

# alter authorisation database to allow installation of apple components without admin rights
security authorizationdb read system.install.apple-software > /tmp/xcode.plist
defaults write /tmp/xcode.plist rule -array authenticate-session-owner-or-admin
security authorizationdb write system.instal.apple-software < /tmp.xcode.plist

# Notify user all is done
su -l "$consoleuser" -c " "'"'$tn'"'" -title "'"Xcode Install"'" -message "'"Xcode install completed!"'" "

# No more caffeine please. I've a headache.
kill "$caffeinatepid"
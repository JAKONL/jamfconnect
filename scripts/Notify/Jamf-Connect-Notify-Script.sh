#!/bin/zsh
# Copyright (c) 2022 JAMF Software, LLC


#variables
NOTIFY_LOG="/var/tmp/depnotify.log"

#This is used to test connectivity to the Jamf Cloud instance prior to continuing setup. 
#Replace "jamf" with the name of your jamfcloud instance. Ex. "apple" would come from "https://apple.jamfcloud.com"
ORGNAME="jamf"

#How many times to attempt connecting to Jamf Cloud prior to quitting. 
#The default sleep is 6 seconds between attempts. COUNTER=10 is 1 minute of attempts.
COUNTER=10

#For TOKEN_BASIC, use same file path location as set for OIDCIDTokenPath in com.jamf.connect.login
TOKEN_BASIC="/tmp/token"
TOKEN_GIVEN_NAME=$(echo "$(cat $TOKEN_BASIC)" | sed -e 's/\"//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep given_name | cut -d ":" -f2)
TOKEN_UPN=$(echo "$(cat $TOKEN_BASIC)" | sed -e 's/\"//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep upn | cut -d ":" -f2)

echo $TOKEN_GIVEN_NAME
echo $TOKEN_UPN

#Define the cleanUp function prior to the start in case we run into trouble
function cleanUp() {
 ###Clean Up
 sleep 3
 echo "Command: Quit" >> $NOTIFY_LOG
 sleep 1
 rm -rf $NOTIFY_LOG
}

#Define the disableNotify function prior to the start in case we run into trouble
function disableNotify() {
 #6 - Disable notify screen from loginwindow process
 /usr/local/bin/authchanger -reset -JamfConnect	
}
 
echo "STARTING RUN" >> $NOTIFY_LOG # Define the number of increments for the progress bar
echo "Command: Determinate: 6" >> $NOTIFY_LOG

#1 - Introduction window with username and animation
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macbookpro-15-retina-touchid-silver.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Welcome, $TOKEN_GIVEN_NAME" >> $NOTIFY_LOG
echo "Command: MainText: Your Mac is now enrolled and will be automatically configured for you." >> $NOTIFY_LOG
echo "Status: Preparing your new Mac..." >> $NOTIFY_LOG

#This will check for connectivity to the Jamf server prior to continuing.
#If this fails longer than the number of tries configured above in the COUNTER variable the user will be landed on their desktop.
until curl -sSf "https://${ORGNAME}.jamfcloud.com/api" > /dev/null; do 
 if (( COUNTER == 0 )); then
  cleanUp
  disableNotify
  exit
 else
  ((COUNTER--))
  sleep 6
 fi
done 

#2 - Setting up single sign-on passwords for local account
echo "Command: Image: /System/Applications/Utilities/Keychain Access.app/Contents/Resources/AppIcon.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Tired of remembering multiple passwords? \n $TOKEN_GIVEN_NAME " >> $NOTIFY_LOG
echo "Command: MainText: We use single sign-on services to help you sign in to each of our corporate services.
Use your email address and account password to sign in to all necessary applications." >> $NOTIFY_LOG
echo "Status: Setting the password for your Mac to sync with your network password..." >> $NOTIFY_LOG
sleep 10
 
#3 - Self Service makes the Mac life easier
echo "Command: Image: /Applications/Self Service.app/Contents/Resources/AppIcon.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Self Service makes Mac life easier" >> $NOTIFY_LOG
echo "Command: MainText: Self Service includes helpful bookmarks and installers for other applications that may interest you." >> $NOTIFY_LOG
echo "Status: Installing Self Service..." >> $NOTIFY_LOG
sleep 10
 
#4 - Everything you need for your first day
###Jamf Triggers
echo "Command: Image: /System/Library/CoreServices/Install in Progress.app/Contents/Resources/Installer.icns" >> $NOTIFY_LOG
echo "Command: MainTitle: Installing everything you need for your first day." >> $NOTIFY_LOG
echo "Command: MainText: All the apps you will need today are already being installed. When setup is complete, you'll find Microsoft Office, Slack, and Zoom are all ready to go. Launch apps from the Dock and have fun!" >> $NOTIFY_LOG
echo "Status: Installing Microsoft Office..." >> $NOTIFY_LOG
/usr/local/bin/jamf policy -event "InstallOffice"
sleep 5
 
#5 - Finishing up
echo "Command: Image: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ApplicationsFolderIcon.icns" >> $NOTIFY_LOG
echo "Status: Installing Slack..." >> $NOTIFY_LOG
/usr/local/bin/jamf policy -event "InstallSlack"
sleep 5
echo "Status: Finishing up... We're almost ready for you, $TOKEN_GIVEN_NAME" >> $NOTIFY_LOG
sleep 3


#Run the cleanUp and disableNotify functions if we have made it this far
cleanUp
disableNotify

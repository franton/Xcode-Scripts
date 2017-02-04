Xcode Scripts
=============

Let me start by stating the obvious. I dislike Xcode and it's many intricacies in delivering it to users.

The munki project has a great wiki on Xcode and some of the things you have to do to give a good user experience out of the box. You can find their very useful work in this project. https://github.com/munki/munki/wiki/Xcode

That is the finalise script and I do not take any credit for it whatsoever.

The finalise script only goes so far. You still require admin rights to install things like the documentation and particularly the code simulators. This is a pain when you're in an environment that prohibits anyone having admin access ever. Hence the simulator script.

I'm running this as part of a Casper / JAMF Pro policy to install Xcode. I deploy Xcode then run "finalise" script immediately afterwards. The "simulator" script is also run from Self Service, and it's using Terminal Notifier to provide feedback as to what's going on to the user. Good thing too, otherwise it'd just happily sit there and people would wonder if it's crashed or not.

This version uses terminal notifier with a custom bundle ID to notify the user of what it's doing. It also uses cocoaDialog to prompt the user which simulator(s) they want.

I'm hoping this will be handy for environments where admin rights are not permitted, while still allowing users to install this stuff themselves.
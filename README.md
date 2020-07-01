#  TetherStatus

This is an app that shows the battery strength, signal strength and network type of the iPhone tethered to a Mac.

![The app in use](Screenshot.png "The app in use")

I created this app so users wouldn't have to click on the wireless status bar icon to view the details.

The app uses APIs internal to macOS which were identified by debugging WiFiAgent and some other inbuilt applications. There's a wealth of information behind the scenes (particularly if you use the internal XPC interface), including mobile carrier details. Unfortunately, to get extra details via XPC in a manner that is acceptable to the average Joe/Jane, we either need to disable System Integrity Protection (SIP) or have Apple Sign our App (lol). 

If you're interested in behind-the-scenes XPC stuff, let me know. I'm surprised at how little this surface has been explored and enumerated.

## Download

You can download the app here: https://github.com/mvknowles/TetherStatus/releases/download/v1.2/TetherStatus.app.zip

## License

Just give me a shout-out, BSD-style if you find this stuff useful.

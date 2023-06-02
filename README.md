
# webrtc_streamer

A Flutter application that streams video with WebRTC Technology. Meant to be used to test and/or use as a boilerplate to build Video Streaming apps/utilities for platforms supported by flutter.

  
## Getting Started

Use `flutter run` to run the app.

> **Prerquisite:** `flutter` should be installed in the device/virtual environment running the above command.
<br> To use the app for a specific target that **does not** have Flutter installed, build the universal, *web app* (with `flutter build web`)  or the target app platform (with `flutter build <target>`) and use the bundle.

## How to use

Every instance of the instance of the application is a peer. Choose STREAMER in one and VIEWER in another.
There are two textboxes below the button, the top one is Local SDP of the peer and the bottom one being the candidate(s).

1. _**Create Offer**_ in the Streamer. The Local SDP and candidate text boxes will get populated.
2.  Copy them and paste them in the Upper textbox of the Viewer and _**Set Remote Desc.**_ and **_Set Candidate_** respectively.
3.  _**Answer**_ in the Viewer. The fields will get populated as well in the Viewer Textboxes.
4.  Repeat Step 2 for the Streamer as well.
5.  Should work...


## Current Limitations

* Due to unavailability of a TURN Server, this does not work outside the LAN. 
A TURN server can be setup easily (maybe using `corturn`) and credentials can be placed in the **configuration** variable (/lib/home.dart line 69)

* There can only be one Streamer and one Viewer of that stream. (For now)

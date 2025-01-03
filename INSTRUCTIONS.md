# Instructions
1. Before getting started, make sure you have Flask installed on Windows. If you don't (or don't know), follow these links first: [installing pip](https://www.geeksforgeeks.org/how-to-install-pip-on-windows/) and [installing flask](https://www.geeksforgeeks.org/how-to-install-flask-in-windows/).
2. Open Retro Gadgets and go to the STEAM WORKSHOP tab in game.
3. Click DISCOVER, and type "Spotify Miniplayer" in the search bar. Find the one with Imber as the author.
4. Add the gadget to your collection.
5. Give the gadget permission to send and recieve network data.
6. Optionally, add it to your launcher.
7. Open your browser and go to [this page](https://developer.spotify.com/documentation/web-api).
8. Log in and create an App.
9. The name and website of the app doesn't matter. Go with http://localhost:3000/callback as your redirect URL (this specific URL can be changed, but if you go with another you must change the code to match).
10. Under APIs used, select the Web API.
11. Take your Client ID and Client Secret, and update the corresponding variables in the CPU0.lua file in Retro Gadgets. Make sure not to publish the device with these left in the code. I recommend adding a security chip, just in case.
12. Download the files startup.bat and startup.py from this repository to an easily accessible place on your computer.
13. Open the text editor and update startup.py with your Client ID and Client Secret.
14. Use the text editor to change the second line of startup.bat to the location of your startup files. If you placed them on your desktop, this line might read "cd C:\Users\johnd\Desktop".
15. Save, and you should be good to go! Make sure your Spotify is running, then launch the app from the system tray or in game.
16. Open startup.bat, and you should have a connection. This can also be done in the reverse order, where you open startup.bat and then launch the gadget. You'll need to open startup.bat to get an authorization code each time you launch the miniplayer. Happy listening!

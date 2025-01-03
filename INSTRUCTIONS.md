# Instructions
1. Open Retro Gadgets and go to the STEAM WORKSHOP tab in game.
2. Click DISCOVER, and type "Spotify Miniplayer" in the search bar. Find the one with Imber as the author.
3. Add the gadget to your collection.
4. Give the gadget permission to send and recieve network data.
5. Optionally, add it to your launcher.
6. Open your browser and go to [this page](https://developer.spotify.com/documentation/web-api).
7. Log in and create an App.
8. The name and website of the app doesn't matter. Go with http://localhost:3000/callback as your redirect URL (this specific URL can be changed, but if you go with another you must change the code to match).
9. Under APIs used, select the Web API.
10. Take your Client ID and Client Secret, and update the corresponding variables in the CPU0.lua file in Retro Gadgets. Make sure not to publish the device with these left in the code. I recommend adding a security chip, just in case.
11. 

-- Variables
local screen, segment, font, slider, wifi
local title, artist, progress, length, isPlaying, volume, spotVolume
local clientID, clientSecret, redirectURL, authCode, token, refreshToken
local elapsedTokenTime = 0
local json = require("json.lua")

-- Request Handles
local tokenRequestHandle, refreshTokenRequestHandle, playerDataRequestHandle, authCodeRequestHandle
local playRequestHandle, pauseRequestHandle, skipBackRequestHandle, skipForwardRequestHandle, volumeRequestHandle

-- Initialization
function init()
	screen = gdt.VideoChip0
  	screen:RenderOnScreen()
  	segment = gdt.SegmentDisplay0
  	font = gdt.ROM.System.SpriteSheets["StandardFont"]
  	slider = gdt.Slider0
  	wifi = gdt.Wifi0

  	title, artist = "NO CONNECTION", "run startup.bat"
  	progress, length, spotVolume, volume = 0, 10, 50, slider.Value
  	isPlaying = false

  	-- fill these in using the spotify api dashboard   
  	clientID = "YOUR_CLIENT_ID"
  	clientSecret = "YOUR_CLIENT_SECRET"
  	redirectURL = "http://localhost:3000/callback"
  	authCode, token, refreshToken = nil, nil, nil

  	-- set up segment display
  	segment:SetDigitColor(1, color.white)
  	segment:SetDigitColor(2, color.white)
  	segment:SetDigitColor(3, color.white)
	segment:SetDigitColor(4, color.white)
	segment:SetDigitColor(5, color.white)
	segment:ShowDigit(3, 2)
	segment:ShowDigit(1, 0)
	segment:ShowDigit(2, 0)
	segment:ShowDigit(4, 0)
	segment:ShowDigit(5, 0)
	
  	-- edit the LED colors, if you'd like. 
  	gdt.LedButton0.LedColor = color.red
  	gdt.LedButton1.LedColor = color.red
end

-- draws progress bar and marker on screen
function drawProgressBar()
  	local lineLength, lineY = 119, 28
 	local distance = math.floor((progress / length) * lineLength)
  	screen:DrawLine(vec2(4, lineY), vec2(4 + distance, lineY), color.white)
  	screen:DrawLine(vec2(4 + distance, lineY), vec2(4 + lineLength, lineY), color.gray)
  	screen:FillRect(vec2(3 + distance, lineY - 1), vec2(5 + distance, lineY + 1), color.white)
end

-- prints artist and song title to the screen
function printInfo()
  	-- btwn 4 and 119 pixels
	local xVal = 4
	local titleY = 4
	local artistY = 14
	local rightRectXVal = 113
	local titlePixels = string.len(title) * 5
	local artistPixels = string.len(artist) * 5
		
	screen:DrawText(vec2(xVal, titleY), font, title, color.white, color.clear)
	screen:DrawText(vec2(xVal, artistY), font, artist, color.gray, color.clear)
	screen:FillRect(vec2(0, 0), vec2(xVal, 22), color.black)
	screen:FillRect(vec2(rightRectXVal, 0), vec2(128, 22), color.black)

	if titlePixels > rightRectXVal then
		screen:SetPixel(vec2(rightRectXVal + 2, titleY + 5), color.white)
		screen:SetPixel(vec2(rightRectXVal + 4, titleY + 5), color.white)
		screen:SetPixel(vec2(rightRectXVal + 6, titleY + 5), color.white)
	end
    
	if artistPixels > rightRectXVal then
		screen:SetPixel(vec2(rightRectXVal + 2, artistY + 5), color.gray)
		screen:SetPixel(vec2(rightRectXVal + 4, artistY + 5), color.gray)
		screen:SetPixel(vec2(rightRectXVal + 6, artistY + 5), color.gray)
	end
end

-- writes song progress to the segment display
function updateSegmentDisplay()
  	local min, sec = math.floor(progress / 60), progress % 60
  	segment:ShowDigit(1, math.floor(min / 10))
  	segment:ShowDigit(2, min % 10)
  	segment:ShowDigit(4, math.floor(sec / 10))
  	segment:ShowDigit(5, sec % 10)
end

-- pulls data to update the miniplayer
function fetchSpotifyData()
	if not playerDataRequestHandle then
		local headers = { ["Authorization"] = "Bearer " .. token }
		playerDataRequestHandle = wifi:WebCustomRequest("https://api.spotify.com/v1/me/player", "GET", headers, "", "")
  	end
end

-- gets a token using the authorization code
function fetchSpotifyToken()
	if not tokenRequestHandle and authCode ~= nil then
		log("fetching token")
    		local body = "grant_type=authorization_code&code=" .. authCode .. "&redirect_uri=" .. redirectURL ..
                 	     "&client_id=" .. clientID .. "&client_secret=" .. clientSecret
    		local headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }
    		tokenRequestHandle = wifi:WebCustomRequest("https://accounts.spotify.com/api/token", "POST", headers, "application/x-www-form-urlencoded", body)
  	end
end

-- refreshes our token (initial token expires in 1 hr)
function refreshSpotifyToken()
  	if not refreshTokenRequestHandle then
		local body = "grant_type=refresh_token&refresh_token=" .. refreshToken ..
                 	     "&client_id=" .. clientID .. "&client_secret=" .. clientSecret
    		local headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }
    		refreshTokenRequestHandle = wifi:WebCustomRequest("https://accounts.spotify.com/api/token", "POST", headers, "application/x-www-form-urlencoded", body)
  	end
end

-- gets authorization code from our python script
function fetchAuthCode()
  	if not authCodeRequestHandle then
    		log("fetching auth code")
    		authCodeRequestHandle = wifi:WebGet("http://localhost:3000/auth_code")
  	end
end

-- when play button is pressed
function eventChannel1(sender, event)
  	if not isPlaying and not playRequestHandle and token ~= nil then
    		local url = "https://api.spotify.com/v1/me/player/play"
    		local headers = { ["Authorization"] = "Bearer " .. token }
    		playRequestHandle = wifi:WebCustomRequest(url, "PUT", headers, "", "")
  	end
end

-- when pause button is pressed
function eventChannel2(sender, event)
	if isPlaying and not pauseRequestHandle and token ~= nil then
    		local url = "https://api.spotify.com/v1/me/player/pause"
    		local headers = { ["Authorization"] = "Bearer " .. token }
    		pauseRequestHandle = wifi:WebCustomRequest(url, "PUT", headers, "", "")
  	end
end

-- when skip back button is pressed
-- includes function to reset song progress
function eventChannel3(sender, event)
	if not skipBackRequestHandle and token ~= nil then
		if progress < 5 then
    			local url = "https://api.spotify.com/v1/me/player/previous"
      			local headers = { ["Authorization"] = "Bearer " .. token }
      			skipBackRequestHandle = wifi:WebCustomRequest(url, "POST", headers, "", "")
		else
			local url = "https://api.spotify.com/v1/me/player/seek?position_ms=0"
      			local headers = { ["Authorization"] = "Bearer " .. token }
      			skipBackRequestHandle = wifi:WebCustomRequest(url, "PUT", headers, "", "")
		end
  	end
end

-- when skip forward button is pressed
function eventChannel4(sender, event)
	if not skipForwardRequestHandle and token ~= nil then
		local url = "https://api.spotify.com/v1/me/player/next"
    		local headers = { ["Authorization"] = "Bearer " .. token }
    		skipForwardRequestHandle = wifi:WebCustomRequest(url, "POST", headers, "", "")
  	end
end

-- when volume slider is adjusted
function eventChannel5(sender, event)
  	local newVolume = math.floor(slider.Value)
  	if newVolume ~= spotVolume and not volumeRequestHandle and token ~= nil then
    		local url = "https://api.spotify.com/v1/me/player/volume?volume_percent=" .. newVolume
    		local headers = { ["Authorization"] = "Bearer " .. token }
    		volumeRequestHandle = wifi:WebCustomRequest(url, "PUT", headers, "", "")
  	end
end

-- large function that handles every web call response
function eventChannel6(sender:Wifi, response:WifiWebResponseEvent)
  	-- error handling
	if response.IsError then
    		print("Error: " .. response.ErrorMessage)
    		if response.RequestHandle == tokenRequestHandle then
    			tokenRequestHandle = nil
      			authCode = ""
      			fetchAuthCode() -- Fetch a new auth code if token request fails
	    	elseif response.RequestHandle == playRequestHandle then
     	 		playRequestHandle = nil
	    	elseif response.RequestHandle == pauseRequestHandle then
	      		pauseRequestHandle = nil
  	  	elseif response.RequestHandle == skipBackRequestHandle then
 	     		skipBackRequestHandle = nil
 	   	elseif response.RequestHandle == skipForwardRequestHandle then
  	    		skipForwardRequestHandle = nil
  	  	elseif response.RequestHandle == volumeRequestHandle then
  	    		volumeRequestHandle = nil
		elseif response.RequestHandle == authCodeRequestHandle then
			authCode = ""
    	  		authCodeRequestHandle = nil
   	 	end
  		return
	end

	-- handles requests that don't return data
	if response.RequestHandle == playRequestHandle then
    		playRequestHandle = nil
		return
  	elseif response.RequestHandle == pauseRequestHandle then
    		pauseRequestHandle = nil
		return
  	elseif response.RequestHandle == skipBackRequestHandle then
    		skipBackRequestHandle = nil
		return
  	elseif response.RequestHandle == skipForwardRequestHandle then
    		skipForwardRequestHandle = nil
		return
  	elseif response.RequestHandle == volumeRequestHandle then
    		volumeRequestHandle = nil
		return 
	end

	-- handles requests that return data
	local data = json.decode(response.Text)

  	if response.RequestHandle == tokenRequestHandle then
  		token, refreshToken = data.access_token, data.refresh_token
    		tokenRequestHandle = nil
  	elseif response.RequestHandle == refreshTokenRequestHandle then
    		token = data.access_token
   		refreshTokenRequestHandle = nil
				
	-- this function gets the data we need to update the screen and segment display
  	elseif response.RequestHandle == playerDataRequestHandle then
  		if data and data.item then
    			artist, title = data.item.artists[1].name, data.item.name
			-- if there are multiple artists, pull their names
			if table.getn(data.item.artists) > 1 then
				for i = 2, table.getn(data.item.artists) do
					artist = artist .. ", " .. data.item.artists[i].name
				end
			end

			progress = math.floor(data.progress_ms / 1000)
      			length = math.floor(data.item.duration_ms / 1000)
      			spotVolume = data.device.volume_percent
      			isPlaying = data.is_playing
    		end
    		playerDataRequestHandle = nil
  	elseif response.RequestHandle == authCodeRequestHandle then
    		authCode = data.authorization_code
    		authCodeRequestHandle = nil
  	end
end

-- Main Update Loop
function update()
	
	-- get our codes and initial token, then get data
 	if authCode == nil then
		authCodeRequestHandle = nil
    		fetchAuthCode()
  	else 
    		if token == nil then
    			fetchSpotifyToken()
    		else
      			fetchSpotifyData()
    		end
	end
		
	-- refreshes our token before an hour is up
  	elapsedTokenTime = elapsedTokenTime + gdt.CPU0.DeltaTime
  	if elapsedTokenTime > 3000 then
    		refreshSpotifyToken()
    		elapsedTokenTime = 0
  	end

	-- update our displays
  	updateSegmentDisplay()
  	screen:Clear(color.black)
  	drawProgressBar()
  	printInfo()
		
	-- play and pause LED states
	gdt.LedButton0.LedState = isPlaying
	gdt.LedButton1.LedState = not isPlaying

  	sleep(.3)
end

init()

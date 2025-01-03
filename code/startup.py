import json
from flask import Flask, request, redirect

app = Flask(__name__)

# Configuration: Replace with your Spotify app's details
SPOTIFY_CLIENT_ID = ""
SPOTIFY_CLIENT_SECRET = ""
REDIRECT_URI = "http://localhost:3000/callback"
SCOPES = "user-read-playback-state user-modify-playback-state user-read-currently-playing"

# Authorization URL for Spotify
SPOTIFY_AUTH_URL = (
    f"https://accounts.spotify.com/authorize"
    f"?client_id={SPOTIFY_CLIENT_ID}"
    f"&response_type=code"
    f"&redirect_uri={REDIRECT_URI}"
    f"&scope={SCOPES}"
)

# Storage for the authorization code
auth_data = {"authorization_code": None}

# Step 1: Redirect user to Spotify's authorization page
@app.route('/login', methods=['GET'])
def login():
    return redirect(SPOTIFY_AUTH_URL)

# Step 2: Spotify redirects back with the authorization code
@app.route('/callback', methods=['GET'])
def callback():
    code = request.args.get('code')
    if code:
        auth_data['authorization_code'] = code
        return f"Authorization code received: {code}"
    else:
        error = request.args.get('error', 'Unknown error')
        return f"Error during authorization: {error}"

# Endpoint to retrieve the authorization code
@app.route('/auth_code', methods=['GET'])
def get_auth_code():
    return json.dumps(auth_data)

if __name__ == '__main__':
    app.run(debug=True, host='localhost', port=3000)
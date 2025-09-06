#!/bin/bash

# Start ngrok in background
ngrok http 8000 > /dev/null 2>&1 &

# Wait for ngrok to start
sleep 2

# Get the forwarding URL from ngrok's API
URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | grep -o 'https://.*' | head -1)

# Update only the ngrokPath value in src/Slack.elm
# This looks for the exact pattern and replaces just the string value
awk -v url="$URL" '
    /^ngrokPath : String$/ { found=1 }
    found && /^ngrokPath =/ {
        print "ngrokPath ="
        print "    \"" url "\""
        getline  # skip the original value line
        found=0
        next
    }
    { print }
' src/Slack.elm > src/Slack.elm.tmp && mv src/Slack.elm.tmp src/Slack.elm

echo "Updated ngrokPath with: $URL"
echo "Press Ctrl+C to stop"

# Keep running
wait
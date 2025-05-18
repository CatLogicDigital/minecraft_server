#!/bin/bash

# Set absolute working directory
cd /home/ec2-user/minecraft || exit 1

# Log the startup
echo "Starting Minecraft server with auto-restart in screen..." >> minecraft.log

# Launch Minecraft server in a detached screen session with auto-restart loop
screen -dmS minecraft bash -c "while true; do
  echo 'Launching Minecraft server...' >> minecraft.log
  java -Xmx1024M -Xms1024M -jar server.jar nogui >> minecraft.log 2>&1
  echo 'Server crashed or stopped. Restarting in 10 seconds...' >> minecraft.log
  sleep 10
done"

# Note: To stop the server loop:
# Reattach: screen -r minecraft
# Stop Minecraft with stop in console.
# Exit the script with Ctrl+C or kill the screen: screen -S minecraft -X quit

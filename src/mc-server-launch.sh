#!/bin/bash

# Set absolute working directory
cd /home/ec2-user/minecraft || exit 1

# Launch Minecraft server with auto-restart loop
while true; do
  echo "Starting Minecraft server with auto-restart in screen..." >> minecraft.log
  screen -dmS minecraft java -Xmx1024M -Xms1024M -jar server.jar nogui >> minecraft.log 2>&1
  echo 'Server crashed or stopped. Restarting in 10 seconds...' >> minecraft.log
  sleep 10
done

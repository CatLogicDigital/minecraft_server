#!/bin/bash

# Set absolute working directory
cd /home/ec2-user/minecraft || exit 1

# Optional: log the startup
echo "Starting Minecraft server in screen..." >> minecraft.log

# Launch Minecraft server in a detached screen session
screen -dmS minecraft java -Xmx1024M -Xms1024M -jar server.jar nogui >> minecraft.log 2>&1

# Optional: verify it was started
if screen -list | grep -q "minecraft"; then
  echo "Minecraft server started in screen session 'minecraft'" >> minecraft.log
else
  echo "Failed to start Minecraft server in screen" >> minecraft.log
fi

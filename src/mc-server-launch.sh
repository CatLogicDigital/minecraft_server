#!/bin/bash

screen -dmS minecraft bash -c "cd /home/ec2-user/minecraft && while true; do
  echo 'Launching Minecraft server...' >> minecraft.log
  java -Xmx1024M -Xms1024M -jar server.jar nogui >> minecraft.log 2>&1
  echo 'Server crashed or stopped. Restarting in 10 seconds...' >> minecraft.log
  sleep 10
done"

#!/bin/bash
#cd /home/ec2-user/minecraft || exit 1
#
#while true; do
#  echo 'Launching Minecraft server...' >> minecraft.log
#  java -Xmx1024M -Xms1024M -jar server.jar nogui >> minecraft.log 2>&1
#  echo 'Server crashed or stopped. Restarting in 5 seconds...' >> minecraft.log
#  sleep 5
#done

#!/bin/bash

# Set working directory
cd /home/ec2-user/minecraft || exit 1

# Write the loop script to disk
cat > start-loop.sh <<'EOF'
#!/bin/bash
cd /home/ec2-user/minecraft || exit 1
while true; do
  echo 'Launching Minecraft server...' >> minecraft.log
  java -Xmx1024M -Xms1024M -jar server.jar nogui >> minecraft.log 2>&1
  echo 'Server crashed or stopped. Restarting in 5 seconds...' >> minecraft.log
  sleep 5
done
EOF

# Make it executable
chmod +x start-loop.sh

# Flush the write and give a moment for filesystem sync
sync
sleep 1

# Start it inside a screen session with logging to check if screen fails
screen -dmS minecraft /home/ec2-user/minecraft/start-loop.sh

# Log confirmation
echo "Screen launch command issued." >> minecraft.log

# Exit cleanly so Terraform doesn't hang
exit 0

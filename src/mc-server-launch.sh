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

# Write a startup loop to a file
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

# Start it inside a screen session
screen -dmS minecraft ./start-loop.sh
# tell codebuild we are finished
exit 0

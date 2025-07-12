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

cd /home/ec2-user/minecraft || exit 1

# Read flavour from env file
if [ -f /etc/minecraft.env ]; then
  source /etc/minecraft.env
else
  echo "No /etc/minecraft.env found, defaulting to vanilla..."
  FLAVOUR="vanilla"
fi

# Pick the correct jar
if [ "$FLAVOUR" = "neoforge" ]; then
  SERVER_JAR="neoforge-server.jar"
else
  SERVER_JAR="server.jar"
fi

cat > start-loop.sh <<EOF
#!/bin/bash
cd /home/ec2-user/minecraft || exit 1
while true; do
  echo "Launching Minecraft server with $SERVER_JAR..." >> minecraft.log
  java -Xmx1024M -Xms1024M -jar "$SERVER_JAR" nogui >> minecraft.log 2>&1
  echo "Server crashed or stopped. Restarting in 5 seconds..." >> minecraft.log
  sleep 5
done
EOF

chmod +x start-loop.sh

# Start with tmux (creates or attaches to a detached session)
tmux new-session -d -s minecraft './start-loop.sh'

echo "Minecraft server launched in tmux." >> minecraft.log
exit 0

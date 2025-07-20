#!/bin/bash

cd /home/ec2-user/minecraft || exit 1

# Read flavour from env file
if [ -f /etc/minecraft.env ]; then
  source /etc/minecraft.env
else
  echo "No /etc/minecraft.env found, defaulting to vanilla..."
  FLAVOUR="vanilla"
fi

# Generate the start-loop.sh with correct launch command per flavour
cat > start-loop.sh <<EOF
#!/bin/bash
cd /home/ec2-user/minecraft || exit 1
while true; do
  if [ "$FLAVOUR" = "neoforge" ]; then
    echo "Launching NeoForge server using run.sh..." >> minecraft.log
    ./run.sh nogui
  else
    echo "Launching Vanilla server..." >> minecraft.log
    java -Xmx1024M -Xms1024M -jar server.jar nogui >> minecraft.log 2>&1
  fi
  echo "Server crashed or stopped. Restarting in 5 seconds..." >> minecraft.log
  sleep 5
done
EOF

chmod +x start-loop.sh

# Start with tmux (creates or attaches to a detached session)
tmux new-session -d -s minecraft './start-loop.sh'

echo "Minecraft server launched in tmux." >> minecraft.log
exit 0

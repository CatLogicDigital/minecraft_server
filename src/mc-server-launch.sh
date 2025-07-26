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
source /etc/minecraft.env
while true; do
  if [ "\$FLAVOUR" = "neoforge" ]; then
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

# Generate the mc-backup.sh that checks player count and backs up if idle for 60 min
cat > mc-backup.sh <<'EOF'
#!/bin/bash
cd /home/ec2-user/minecraft || exit 1

tmux send-keys -t minecraft "list" C-m
sleep 2
output=$(tmux capture-pane -pt minecraft -S -100)
player_count=$(echo "$output" | grep "There are " | tail -n 1 | grep -oP 'There are \K[0-9]+')
echo "Players online: $player_count"

flavour=$(cat /etc/minecraft.env)
zero_count_file="/tmp/mc-zero-count"

if [ "$player_count" == "0" ]; then
    count=$(cat "$zero_count_file" 2>/dev/null || echo 0)
    count=$((count + 1))
    echo $count > "$zero_count_file"
else
    echo 0 > "$zero_count_file"
fi

# If idle for 60 min (1 x 10min intervals)
if [ "$count" -ge 1 ]; then
    echo "Server idle period met. Creating backup zip..."
    ts=$(date +"%Y%m%d_%H%M%S")
    zip_name="${ts}__minecraft_backup.zip"
    zip -rq "$zip_name" Ella* -x "logs/*"
    aws s3 cp "$zip_name" s3://catlogic-mc-backup/$flavour/
    aws s3 cp s3://catlogic-mc-backup/$flavour/"$zip_name" s3://catlogic-mc-backup/$flavour/minecraft_backup.zip

    echo "Backup complete. Terminating instance..."
    #aws ec2 terminate-instances --instance-ids $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --region eu-west-2
fi
EOF

chmod +x mc-backup.sh

# Start with tmux (creates or attaches to a detached session)
tmux new-session -d -s minecraft './start-loop.sh'

# Schedule mc-backup.sh to run every 10 minutes
(crontab -l 2>/dev/null; echo "*/10 * * * * /home/ec2-user/minecraft/mc-backup.sh >> /home/ec2-user/minecraft/backup.log 2>&1") | crontab -

echo "Minecraft server launched in tmux." >> minecraft.log
exit 0

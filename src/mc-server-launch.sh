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

cat > start-loop.sh <<'EOF'
#!/bin/bash
#cd /home/ec2-user/minecraft || exit 1
#while true; do
#re add indent ##
echo 'Launching Minecraft server...' >> minecraft.log
java -Xmx1024M -Xms1024M -jar server.jar nogui
echo 'Server crashed or stopped. Restarting in 5 seconds...' >> minecraft.log
sleep 5
#done
EOF

chmod +x start-loop.sh

# Start with tmux (creates or attaches to a detached session)
tmux new-session -d -s minecraft './start-loop.sh'

echo "Minecraft server launched in tmux." >> minecraft.log
exit 0

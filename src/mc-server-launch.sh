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
cd /home/ec2-user/minecraft || exit 1
while true; do
  echo 'Launching Minecraft server...' >> minecraft.log
  java -Xmx1024M -Xms1024M -jar server.jar nogui >> minecraft.log 2>&1
  echo 'Server crashed or stopped. Restarting in 5 seconds...' >> minecraft.log
  sleep 5
done
EOF

chmod +x start-loop.sh
sync
sleep 1

# Fully detach the screen session from Terraform/CodeBuild
setsid screen -dmS minecraft ./start-loop.sh < /dev/null &> /dev/null &

echo "Screen launch command issued." >> minecraft.log
exit 0

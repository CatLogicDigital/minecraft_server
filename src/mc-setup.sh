# Install Java 21 (Amazon Corretto)
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -Lo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo yum install -y java-21-amazon-corretto-devel

# copy tf templates to minecraft backup bucket
aws s3 cp config.tf s3://$1
aws s3 cp variables.tf s3://$1
aws s3 cp account.tfvars s3://$1

# create minecraft dir and sync with world backup bucket 
mkdir minecraft

# copy the backup zip over
aws s3 cp s3://$1/2025_04_06_minecraft_backup.zip minecraft-backup.zip --no-progress --cli-read-timeout 0 --cli-connect-timeout 0
# unzip the backup
unzip -o minecraft-backup.zip -d minecraft

# install minecraft if this is the first time
if [ ! -f "minecraft/eula.txt" ]; then
    echo "Installing Minecraft"
    cd minecraft
        wget https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar
        java -Xmx1024M -Xms1024M -jar server.jar nogui

    echo "### Accepting EULA"
    echo "eula=true" > eula.txt

    echo "### Setting server properties"
    cat > server.properties <<EOF
difficulty=normal
gamemode=creative # or survival, adventure, spectator
level-name=Ella
motd=Meow :3
pvp=true
EOF

fi

# Set view-distance to 16 in server.properties ###max is 32, default is 10
if [ -f "minecraft/server.properties" ]; then
    sed -i 's/^view-distance=.*/view-distance=16/' minecraft/server.properties
fi

# Create ops.json to assign operator privileges
cat > minecraft/ops.json <<EOF
[
  {
    "uuid": "b9ae6d1a-9f42-4208-8424-974695949992",
    "name": "Instant_Fail",
    "level": 4,
    "bypassesPlayerLimit": false
  },
  {
    "uuid": "263c8457-58d7-4bcc-908f-e6ca9690a377",
    "name": "LunarKitty",
    "level": 4,
    "bypassesPlayerLimit": false
  }
]
EOF

# install pip
# rem
# install minecraft status 
echo "Installing Minecraft Status [mcstatus]"
sudo pip3 install mcstatus
export PATH=$PATH:/usr/local/bin

# insert auto-shutoff into cron tab and run each minute
###(crontab -l 2>/dev/null; echo "* * * * * PATH=$PATH:/usr/local/bin python3 auto-shutoff.py s3://$1 $2 $3") | crontab -

# Start Minecraft in a named screen session called "minecraft"
screen -S minecraft -dm java -Xmx1024M -Xms1024M -jar server.jar nogui
#cd minecraft
#    rm -f nohup.out || true
#    # copying from S3 drops the executable bit
#    chmod a+x run_nogui.sh
#    nohup ./run_nogui.sh &
#    sleep 10
#    cat nohup.out
#cd ..

# Wait for the server to start
echo "Waiting for server to start..."

# Wait until the log file exists
while [ ! -f minecraft/logs/latest.log ]; do
    sleep 1
done

# Wait until "Done" appears in the log
timeout 60 bash -c 'until grep -q "Done (" minecraft/logs/latest.log; do sleep 1; done'
echo "Server startup detected."

echo "Server is ready :3"

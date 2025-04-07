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
aws s3 cp s3://$1/20250406_201203__minecraft_backup.zip minecraft-backup.zip --no-progress --cli-read-timeout 0 --cli-connect-timeout 0
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
fi

echo "Setting server properties"
set_prop() {
    key="$1"
    value="$2"
    file="server.properties"
    if grep -q "^$key=" "$file"; then
        sed -i "s/^$key=.*/$key=$value/" "$file"
    else
        echo "$key=$value" >> "$file"
    fi
}

set_prop level-name Ella
set_prop enable-command-block true
set_prop gamemode survival
set_prop motd "meow :3"
set_prop view-distance 25
#view distance default 10 max 32

# Create ops.json to assign operator privileges
cat > ops.json <<EOF
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
#echo "Installing Minecraft Status [mcstatus]"
#sudo pip3 install mcstatus
#export PATH=$PATH:/usr/local/bin

# insert auto-shutoff into cron tab and run each minute
###(crontab -l 2>/dev/null; echo "* * * * * PATH=$PATH:/usr/local/bin python3 auto-shutoff.py s3://$1 $2 $3") | crontab -

# Start Minecraft in a named screen session called "minecraft"
#screen -S minecraft -dm java -Xmx1024M -Xms1024M -jar server.jar nogui
screen java -Xmx1024M -Xms1024M -jar server.jar nogui
#screen -S minecraft -dm bash -c "java -Xmx1024M -Xms1024M -jar server.jar nogui"


echo "Server is ready :3"

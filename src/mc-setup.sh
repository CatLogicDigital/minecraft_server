# Install Java 21 (Amazon Corretto)
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -Lo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo yum install -y java-21-amazon-corretto-devel
# install tmux
sudo yum install -y tmux

# copy tf templates to minecraft backup bucket
aws s3 cp config.tf s3://$1
aws s3 cp variables.tf s3://$1
aws s3 cp account.tfvars s3://$1

# create minecraft dir and sync with world backup bucket 
mkdir minecraft

# copy the backup zip over
aws s3 cp s3://$1/minecraft_backup.zip minecraft_backup.zip --quiet --cli-read-timeout 0 --cli-connect-timeout 0

# unzip the backup
#unzip -o minecraft_backup.zip -d minecraft
unzip -o minecraft_backup.zip

# install minecraft if this is the first time
# navigate into mincraft dir
cd minecraft
if [ ! -f "minecraft/eula.txt" ]; then
    echo "Installing Minecraft"
        # https://jars.vexyhost.com/
        wget https://piston-data.mojang.com/v1/objects/6e64dcabba3c01a7271b4fa6bd898483b794c59b/server.jar
        java -Xmx1024M -Xms1024M -jar server.jar nogui
    echo "### Accepting EULA"
    echo "eula=true" > eula.txt
    cd ..
fi

cd minecraft
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
set_prop view-distance 22
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

# copy the custom server icon
aws s3 cp s3://$1/server-icon.png server-icon.png --quiet --cli-read-timeout 0 --cli-connect-timeout 0

# install pip
# rem
# install minecraft status 
#echo "Installing Minecraft Status [mcstatus]"
#sudo pip3 install mcstatus
#export PATH=$PATH:/usr/local/bin

# insert auto-shutoff into cron tab and run each minute
###(crontab -l 2>/dev/null; echo "* * * * * PATH=$PATH:/usr/local/bin python3 auto-shutoff.py s3://$1 $2 $3") | crontab -

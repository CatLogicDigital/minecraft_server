#!/bin/bash

flavour="neoforge"
# vanilla
# neoforge

minecraft_jar='https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar' # 1.21.8 # https://jars.vexyhost.com/

# save the envinment version so we can seperaout backups
echo "FLAVOUR=$flavour" | sudo tee /etc/minecraft.env
source /etc/minecraft.env
echo $FLAVOUR

# Install Java 21 (Amazon Corretto)
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -Lo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo yum install -y java-21-amazon-corretto-devel
# install tmux, unzip, python3
sudo yum install -y tmux unzip python3 python3-pip

# copy tf templates to minecraft backup bucket
aws s3 cp config.tf s3://$1
aws s3 cp variables.tf s3://$1
aws s3 cp account.tfvars s3://$1

# create minecraft dir and sync with world backup bucket 
mkdir minecraft

# copy the backup zip over
aws s3 cp s3://$1/$FLAVOUR/minecraft_backup.zip minecraft_backup.zip --cli-read-timeout 0 --cli-connect-timeout 0

# unzip the backup
unzip -o minecraft_backup.zip -d minecraft

cd minecraft

if [ "$flavour" = "vanilla" ]; then
    # install minecraft
    # navigate into mincraft dir
    echo "Installing Minecraft"
    wget "$minecraft_jar" -O server.jar
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    echo "### Accepting EULA"
    echo "eula=true" > eula.txt

elif [ "$flavour" = "neoforge" ]; then
    echo "Installing NeoForge"
    wget "$minecraft_jar" -O server.jar
    java -Xmx1024M -Xms1024M -jar server.jar nogui # to generate server proprties file
    echo "### Accepting EULA"
    echo "eula=true" > eula.txt
    # https://neoforged.net/
    wget https://maven.neoforged.net/releases/net/neoforged/neoforge/21.8.15/neoforge-21.8.15-installer.jar -O neoforge-installer.jar
    java -jar neoforge-installer.jar --installServer
    chmod +x run.sh
    rm -f neoforge-installer.jar

    mkdir -p mods # create the mods folder

    echo "Installing MC-Modrinth-Project-Manager"
    pip3 install "urllib3<2" "requests<2.32"
    curl -Lo mcsmp.py https://raw.githubusercontent.com/un-pogaz/MC-Modrinth-Project-Manager/main/mcsmp.py
    chmod +x mcsmp.py
    
    # Patch mcsmp.py to fix ISO date parsing with trailing 'Z'
    pip3 install python-dateutil
    if ! grep -q 'from dateutil.parser import isoparse' mcsmp.py; then
        sed -i '/^import /a from dateutil.parser import isoparse' mcsmp.py
    fi
    sed -i 's/datetime.fromisoformat/isoparse/g' mcsmp.py

    echo "Writing mod list to mods.txt"
    cat > mods.txt <<EOF
worldedit
jei
waystones
wthit
mob-lassos
xaeros-minimap
EOF

    echo "Installing MODS via Modrinth API"
    python3 mcsmp.py directory-add minecraft /home/ec2-user/minecraft minecraft
    python3 mcsmp.py version minecraft 1.21.7
    python3 mcsmp.py loader minecraft neoforge

    while IFS= read -r mod; do
        echo "Installing MOD: $mod"
        python3 mcsmp.py install minecraft "$mod"
    done < mods.txt
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
set_prop view-distance 22

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

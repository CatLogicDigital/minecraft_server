flavour="vanilla"
#vanilla
#neoforge

minecraft_jar='https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar' # 1.21.8 # https://jars.vexyhost.com/

# save the envinment version so we can seperaout backups
echo "FLAVOUR=$flavour" | sudo tee /etc/minecraft.env
source /etc/minecraft.env
echo $FLAVOUR

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
    wget https://maven.neoforged.net/releases/net/neoforged/neoforge/21.7.20-beta/neoforge-21.7.20-beta-installer.jar -O neoforge-installer.jar
    java -jar neoforge-installer.jar --installServer
    rm -f neoforge-installer.jar
    # Always accept the EULA
    echo "eula=true" > eula.txt

    mkdir -p mods # create the mods folder
    echo "MODS --- Installing WorldEdit for NeoForge"
    #https://modrinth.com/plugin/worldedit?version=1.21.7&loader=neoforge
    wget -O mods/worldedit-mod-7.3.15.jar https://cdn.modrinth.com/data/1u6JkXh5/versions/6stG33I5/worldedit-mod-7.3.15.jar
    echo "MODS --- Installing Just Enough Items for NeoForge"
    #https://modrinth.com/mod/jei?version=1.21.7&loader=neoforge
    wget -O mods/jei-1.21.7-neoforge-23.1.0.4.jar https://cdn.modrinth.com/data/u6dRKJwZ/versions/Cp9YPdzb/jei-1.21.7-neoforge-23.1.0.4.jar
    echo "MODS --- Installing Waystones for NeoForge"
    #https://modrinth.com/mod/waystones?version=1.21.7&loader=neoforge
    wget -O mods/waystones-neoforge-1.21.7-21.7.1.jar https://cdn.modrinth.com/data/LOpKHB2A/versions/CYru1h3x/waystones-neoforge-1.21.7-21.7.1.jar
    echo "MODS --- Installing What The Hell Is That? for NeoForge"
    #https://modrinth.com/mod/waystones?version=1.21.7&loader=neoforge
    wget -O mods/wthit-neo-16.0.1.jar https://cdn.modrinth.com/data/6AQIaxuO/versions/tWbt6XcK/wthit-neo-16.0.1.jar
    echo "MODS --- Mob Loassos for NeoForge"
    https://modrinth.com/mod/mob-lassos?version=1.21.7&loader=neoforge#download
    wget -O mods/MobLassos-v21.7.0-1.21.7-NeoForge.jar https://cdn.modrinth.com/data/ftOBbnu8/versions/2MCxG8Tj/MobLassos-v21.7.0-1.21.7-NeoForge.jar
    echo "MODS --- Xaero's Minimap for NeoForge"
    https://modrinth.com/mod/xaeros-minimap?version=1.21.7&loader=neoforge#download
    wget -O mods/Xaeros_Minimap_25.2.10_NeoForge_1.21.7.jar https://cdn.modrinth.com/data/1bokaNcj/versions/JWQzpqe6/Xaeros_Minimap_25.2.10_NeoForge_1.21.7.jar
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

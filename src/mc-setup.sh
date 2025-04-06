# sudo yum update -y
#sudo yum install java-1.8.0 -y
#sudo yum remove java-1.7.0-openjdk -y

# install Java
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
aws s3 sync s3://$1 minecraft/

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

# install pip
sudo yum install -y python3-pip
# install minecraft status 
echo "Installing Minecraft Status [mcstatus]"
sudo pip install mcstatus

# insert auto-shutoff into cron tab and run each minute
(crontab -l 2>/dev/null; echo "* * * * * python3 auto-shutoff.py s3://$1 $2 $3") | crontab -

# start minecraft (does not return)
screen java -Xmx1024M -Xms1024M -jar server.jar nogui

# op the player after startup
sleep 10
screen -S minecraft -p 0 -X stuff "op InstantFail$(printf '\r')"
screen -S minecraft -p 0 -X stuff "op Xaellavie$(printf '\r')"

#cd minecraft
#    rm nohup.out || true
#    # copying from S3 drops the x perm
#    chmod a+x run_nogui.sh
#    nohup ./run_nogui.sh &
#    sleep 10
#    cat nohup.out
#cd ..

# sudo yum update -y
#sudo yum install java-1.8.0 -y
#sudo yum remove java-1.7.0-openjdk -y

# install Java
sudo yum install java-17-amazon-corretto -y || sudo apt install openjdk-17-jre-headless -y

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
        # https://www.minecraft.net/en-us/download/server
        #wget https://launcher.mojang.com/v1/objects/bb2b6b1aefcd70dfd1892149ac3a215f6c636b07/server.jar
        wget https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar
        # run the jar file for the first time. It will fail but don’t worry about it, that is expected behavior. Run this command:
        #java -Xmx1024M -Xms1024M -jar minecraft_server.1.21.5.jar nogui
        java -Xmx1024M -Xms1024M -jar server.jar nogui

    echo "### Accepting EULA"
    echo "eula=true" > eula.txt
    
    echo "### Setting server properties"
    cat > server.properties <<EOF
    difficulty=normal
    gamemode=survival
    level-name=world
    motd=Welcome to CatLogic Minecraft
    pvp=true
    EOF


    cd ..
fi

# install minecraft status 
echo "Installing Minecraft Status [mcstatus]"
sudo pip install mcstatus

# insert auto-shutoff into cron tab and run each minute
crontab -l | { cat; echo "* * * * * python auto-shutoff.py s3://$1 $2 $3"; } | crontab -

# start minecraft (does not return)
screen java -Xmx1024M -Xms1024M -jar server.jar nogui
#cd minecraft
#    rm nohup.out || true
#    # copying from S3 drops the x perm
#    chmod a+x run_nogui.sh
#    nohup ./run_nogui.sh &
#    sleep 10
#    cat nohup.out
#cd ..

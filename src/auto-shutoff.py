from mcstatus import MinecraftServer
import time
import os.path
import subprocess
import sys
import datetime

def check_call(args):
    proc = subprocess.Popen(args,
                            shell=True,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            cwd='/tmp')
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        print(stdout.decode())
        print(stderr.decode())
        raise subprocess.CalledProcessError(proc.returncode, args)

server = MinecraftServer.lookup("localhost:25565")
status = server.status()

last_activity_file = '/tmp/mc_last_activity'
backup_marker = '/tmp/mc_backup'

# Check for last recorded activity
if os.path.exists(last_activity_file):
    with open(last_activity_file, 'r+') as f:
        if status.players.online:
            # Players are online; update activity timestamp
            f.seek(0)
            f.write(str(time.time()))
            f.truncate()

            # Remove existing backup marker if players reconnect
            if os.path.exists(backup_marker):
                os.remove(backup_marker)
        else:
            old_time = float(f.read())
            time_past = time.time() - old_time

            # Check inactivity period (1 hour)
            if time_past > (60 * 60):
                if not os.path.exists(backup_marker):
                    with open(backup_marker, 'w') as p:
                        p.write(str(time.time()))

                    # Create timestamped zip file
                    timestamp = datetime.datetime.utcnow().strftime("%Y%m%d_%H%M%S")
                    zip_name = f"/tmp/{timestamp}__minecraft_backup.zip"
                    check_call(f'cd /home/ec2-user && zip -r {zip_name} minecraft -x "minecraft/logs/*"')

                    # Upload to S3
                    s3_base = sys.argv[1].rstrip('/')
                    s3_path = f'{s3_base}/{timestamp}__minecraft_backup.zip'
                    static_path = f'{s3_base}/minecraft_backup.zip'

                    check_call(f'aws s3 cp {zip_name} {s3_path} --no-progress --cli-read-timeout 0 --cli-connect-timeout 0')
                    check_call(f'aws s3 cp {s3_path} {static_path}')

                # Trigger server shutdown
                check_call(f'aws sns publish --topic-arn {sys.argv[2]} --message "{{}}" --region {sys.argv[3]}')
                os.remove(last_activity_file)
else:
    # Initialize activity timestamp
    with open(last_activity_file, 'w') as f:
        f.write(str(time.time()))

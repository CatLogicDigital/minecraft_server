# -*- coding: utf-8 -*-

import os
import subprocess
import urllib.request
import requests
import boto3
import json

# Explicitly populated variables
TERRAFORM_VERSION = '1.5.7'
AWS_REGION = 'eu-west-2'
EC2_KEY_PAIR_NAME = 'minecraft-key'
TF_BUCKET = 'terraform-state-catlogic'
MC_BACKUP_BUCKET_NAME = 'catlogic-mc-backup'

TERRAFORM_LINUX_DOWNLOAD_URL = (
    f'https://releases.hashicorp.com/terraform/{TERRAFORM_VERSION}/terraform_{TERRAFORM_VERSION}_linux_amd64.zip'
)

EXEC_DIR = '/tmp'
TERRAFORM_DIR = os.path.join(EXEC_DIR, f'terraform_{TERRAFORM_VERSION}')
TERRAFORM_PATH = os.path.join(TERRAFORM_DIR, 'terraform')

# Terraform state details
TERRAFORM_STATE_S3_BUCKET = TF_BUCKET
TERRAFORM_STATE_KEY = 'mc-server.tfstate'

# Backup bucket
MC_BACKUP_S3_BUCKET = MC_BACKUP_BUCKET_NAME


def send_discord_message(message):
    url = ""  # Your discord webhook URL here
    data = json.dumps({'content': message})
    headers = {"Content-Type": "application/json", "User-Agent": "minecraft-destroy"}
    requests.post(url, data=data, headers=headers)


def check_call(args):
    proc = subprocess.Popen(args,
                            shell=True,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            cwd=EXEC_DIR)
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        print(stdout.decode())
        print(stderr.decode())
        raise subprocess.CalledProcessError(proc.returncode, args)


def install_terraform():
    if os.path.exists(TERRAFORM_PATH):
        return

    urllib.request.urlretrieve(TERRAFORM_LINUX_DOWNLOAD_URL, '/tmp/terraform.zip')
    check_call(f'unzip -o /tmp/terraform.zip -d {TERRAFORM_DIR}')
    check_call(f'{TERRAFORM_PATH} --version')


def destroy_terraform_plan():
    s3 = boto3.resource('s3', region_name=AWS_REGION)

    # Download TF configuration files
    s3.Object(MC_BACKUP_S3_BUCKET, 'config.tf').download_file('/tmp/config.tf')
    s3.Object(MC_BACKUP_S3_BUCKET, 'account.tfvars').download_file('/tmp/account.tfvars')
    s3.Object(MC_BACKUP_S3_BUCKET, 'variables.tf').download_file('/tmp/variables.tf')

    # Initialize Terraform
    check_call(f'{TERRAFORM_PATH} init -input=false')

    # Download Terraform state
    s3.Object(TERRAFORM_STATE_S3_BUCKET, TERRAFORM_STATE_KEY).download_file('/tmp/terraform.tfstate')

    # Destroy Terraform-managed infrastructure
    check_call(
        f'{TERRAFORM_PATH} destroy -auto-approve -state=/tmp/terraform.tfstate -var-file=/tmp/account.tfvars'
    )

    # Upload updated Terraform state
    s3.meta.client.upload_file('/tmp/terraform.tfstate', TERRAFORM_STATE_S3_BUCKET, TERRAFORM_STATE_KEY)


def handler(event, context):
    send_discord_message("Server is shutting down due to inactivity.")
    install_terraform()
    destroy_terraform_plan()


if __name__ == '__main__':
    install_terraform()
    destroy_terraform_plan()


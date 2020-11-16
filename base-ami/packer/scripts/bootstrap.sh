#!/bin/bash -xe

# Install RDS certs
cd /etc/pki/ca-trust/source/anchors/
curl https://s3.amazonaws.com/rds-downloads/rds-ca-2015-root.pem -o rds-ca-2015-root.pem
curl https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem -o rds-ca-2019-root.pem
cat rds-ca-2015-root.pem rds-ca-2019-root.pem > rds-combined-ca-bundle.pem
ls -l

cd

while [[ -f /var/run/yum.pid ]]; do
  echo "Existing lock /var/run/yum.pid found... Waiting until other process completes."
  sleep 10
done

yum install yum-utils -y

# docker-18.06.1ce-4.amzn2.x86_64 \
yum update -y
yum install \
    https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-oss-7.1.1-x86_64.rpm \
    docker-18.06.1ce-7.amzn2 \
    yum-utils \
    aws-cfn-bootstrap \
    shadow-utils.x86_64 \
    amazon-efs-utils \
    nmap-ncat \
    jq \
    tree \
    tar \
    gzip \
    make \
    unzip \
    python3 \
    python3-devel \
    python3-libs \
    python3-pip \
    python3-setuptools \
    -y

# Amazon Inspector agent
curl -s https://inspector-agent.amazonaws.com/linux/latest/install|bash
yum clean all

# Installing helper tools from pip
pip3 install --upgrade awscli
hash -r
pip3 install \
     pyopenssl \
     boto3 \
     boto \
     ansible==${ANSIBLE_VERSION}

# install and configure ecr credential helper
yum -y install amazon-ecr-credential-helper
mkdir /root/.docker
chmod 0700 /root/.docker
envsubst < /tmp/files/root.docker.config.json > /root/.docker/config.json
chmod 0600 /root/.docker/config.json

# configure docker daemon
cp /tmp/files/docker.daemon.json /etc/docker/daemon.json
chown root:root /etc/docker/daemon.json
chmod 0600 /etc/docker/daemon.json

## Install sysdig agent container
yum -y install kernel-devel-$(uname -r)
systemctl enable docker
systemctl start docker
docker pull docker-mirror.docker.company.com/sysdig/agent:latest

# Install sysdig key - DO NOT ECHO
umask 0077
mkdir /etc/sysdig
mv /tmp/files/sysdig /etc/sysdig/key
chown root:root /etc/sysdig/key
chmod 0600 /etc/sysdig/key

# Setup beats inputs
mkdir -p /etc/filebeat/inputs.d
chmod 0755 /etc/filebeat/inputs.d
mv /tmp/files/filebeat.inputs.system.yml /etc/filebeat/inputs.d/system.yml
chown root:root /etc/filebeat/inputs.d/system.yml
chmod 0644 /etc/filebeat/inputs.d/system.yml

# install ansible playbooks
mkdir -p /etc/ansible/playbooks
cp /tmp/files/ansible.playbook.attach-ebs.yml /etc/ansible/playbooks/attach-ebs.yml
cp /tmp/files/ansible.playbook.attach-eni.yml /etc/ansible/playbooks/attach-eni.yml
cp /tmp/files/ansible.playbook.install-certs.yml /etc/ansible/playbooks/install-certs.yml
cp /tmp/files/ansible.playbook.snapshot-ebs.yml /etc/ansible/playbooks/snapshot-ebs.yml
cp /tmp/files/ansible.playbook.tag-resources.yml /etc/ansible/playbooks/tag-resources.yml
chmod 0755 /etc/ansible /etc/ansible/playbooks
chmod 0644 /etc/ansible/playbooks/*.yml
chown root:root /etc/ansible/playbooks

# clean this instance
systemctl stop rsyslog
shred -u /etc/ssh/*_key /etc/ssh/*_key.pub
find /var/log -type f -exec rm -f {} \;
touch /var/log/lastlog
rm -rf /tmp/files

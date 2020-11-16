#!/bin/bash -xe
# install inspec
export CHEF_LICENSE=accept
curl https://omnitruck.chef.io/install.sh | bash -s -- -P inspec

# HACK - to be removed once inspec works with the new format introduced by Amazon
# in their AMI's since the release of amzn2-ami-hvm-2.0.20181024-x86_64-gp2
echo "Amazon Linux 2" > /etc/system-release

cat > /run/inspec.rb << EOF
control "check versions" do
  impact 1.0

  title "Check ansible version"
  describe command('ansible-playbook --version') do
   its ('stdout') { should include "ansible-playbook 2.6.1" }
  end

  title "Check aws cli"
  describe command('aws --version') do
   its ('stdout') { should include "aws-cli/1" }
  end

  title "Check docker"
  describe command('docker --version') do
   its ('stdout') { should include "Docker version 18.06.1-ce" }
  end

  title "Check filebeat"
  describe command('filebeat version') do
   its ('stdout') { should include "filebeat version 7.1.1" }
  end

  title "Check cfn-init"
  describe command('/opt/aws/bin/cfn-init -h') do
   its ('stdout') { should include "Usage: cfn-init [options]" }
  end

  title "Check efs"
  describe command('/sbin/mount.efs --version') do
   its ('stdout') { should include "/sbin/mount.efs Version:" }
  end

  title "Check jq"
  describe command('jq --version') do
   its ('stdout') { should include "jq-1" }
  end

  title "Check awsagent"
  describe command('file /opt/aws/awsagent/bin/awsagent') do
   its ('stdout') { should include "ELF 64-bit LSB shared object, x86-64" }
  end
end

control "check services" do
  describe service('docker') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control "check docker" do
  describe docker.images.where { repository == 'docker-mirror.docker.company.com/sysdig/agent' && tag == 'latest' } do
     it{ should exist }
  end
end

control "check files" do
  describe file('/etc/sysdig/key') do
    its('md5sum') { should eq '075cd74623e5e176da2caf0a93931984' }
    its('mode') { should cmp '0600' }
    its('owner') { should eq 'root' }
  end
end
EOF

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
inspec exec /run/inspec.rb

# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant multi machine configuration


require 'yaml'
config_yml = YAML.load_file(File.open(__dir__ + '/vagrant-config.yml'))

NON_ROOT_USER = 'vagrant'.freeze

# This script to install k8s using kubeadm will get executed after a box is provisioned
$configureBox = <<-SCRIPT
    # SOURCE: https://askubuntu.com/questions/459402/how-to-know-if-the-running-platform-is-ubuntu-or-centos-with-help-of-a-bash-scri
    # Determine OS platform
    UNAME=$(uname | tr "[:upper:]" "[:lower:]")
    # If Linux, try to determine specific distribution
    if [ "$UNAME" == "linux" ]; then
        # If available, use LSB to identify distribution
        if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
            export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
        # Otherwise, use release info file
        else
            export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
        fi
    fi
    # For everything else (or if above failed), just use generic identifier
    [ "$DISTRO" == "" ] && export DISTRO=$UNAME
    unset UNAME

    echo "============================================="
    echo $DISTRO
    echo $DISTRO
    echo $DISTRO
    echo $DISTRO
    echo $DISTRO
    echo "============================================="

    # install docker v18.09
    # reason for not using docker provision is that it always installs latest version of the docker, but kubeadm requires 18.09 or older

    export DOCKER_COMPOSE_VERSION="1.24.0"
    export DOCKER_VERSION="18.09"
    export IS_CI_ENVIRONMENT="true"

    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-cache search docker
    sudo apt-cache madison docker-ce
    sudo apt-get --allow-downgrades -y -o Dpkg::Options::="--force-confnew" install docker-ce=$(apt-cache madison docker-ce | grep $DOCKER_VERSION | head -1 | awk '{print $3}')
    sudo rm -f /usr/local/bin/docker-compose
    curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin
    docker-compose --version

    # run docker commands as vagrant user (sudo not required)
    usermod -aG docker vagrant

    apt-get install -y apt-transport-https curl

    # ip of this box
    IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`
    sudo apt-get -y install python-minimal python-apt
    sudo apt-get install -y \
              bash-completion \
              curl \
              git \
              vim
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python-six python-pip

    modprobe ip_vs_wrr
    modprobe ip_vs_rr
    modprobe ip_vs_sh
    modprobe ip_vs
    modprobe nf_conntrack_ipv4
    modprobe bridge
    modprobe br_netfilter

    cat <<EOF >/etc/modules-load.d/k8s_ip_vs.conf
ip_vs_wrr
ip_vs_rr
ip_vs_sh
ip_vs
nf_conntrack_ipv4
EOF

    cat <<EOF >/etc/modules-load.d/k8s_bridge.conf
bridge
EOF

    cat <<EOF >/etc/modules-load.d/k8s_br_netfilter.conf
br_netfilter
EOF

    echo "* soft     nproc          500000" > /etc/security/limits.d/perf.conf
    echo "* hard     nproc          500000" >> /etc/security/limits.d/perf.conf
    echo "* soft     nofile         500000" >> /etc/security/limits.d/perf.conf
    echo "* hard     nofile         500000"  >> /etc/security/limits.d/perf.conf
    echo "root soft     nproc          500000" >> /etc/security/limits.d/perf.conf
    echo "root hard     nproc          500000" >> /etc/security/limits.d/perf.conf
    echo "root soft     nofile         500000" >> /etc/security/limits.d/perf.conf
    echo "root hard     nofile         500000" >> /etc/security/limits.d/perf.conf
    sed -i '/pam_limits.so/d' /etc/pam.d/sshd
    echo "session    required   pam_limits.so" >> /etc/pam.d/sshd
    sed -i '/pam_limits.so/d' /etc/pam.d/su
    echo "session    required   pam_limits.so" >> /etc/pam.d/su
    sed -i '/session required pam_limits.so/d' /etc/pam.d/common-session
    echo "session required pam_limits.so" >> /etc/pam.d/common-session
    sed -i '/session required pam_limits.so/d' /etc/pam.d/common-session-noninteractive
    echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive
    # NOTE: https://medium.com/@muhammadtriwibowo/set-permanently-ulimit-n-open-files-in-ubuntu-4d61064429a
    # TODO: Put into playbook
    echo "2097152" | sudo tee /proc/sys/fs/file-max

    apt-get install -y conntrack ipset

    sudo sysctl -w vm.min_free_kbytes=1024000
    sudo sync; sudo sysctl -w vm.drop_caches=3; sudo sync


    echo 1 >/sys/kernel/mm/ksm/run
    echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

    # SOURCE: https://blog.openai.com/scaling-kubernetes-to-2500-nodes/ ( VERY GOOD )

    echo "vm.min_free_kbytes=1024000" | sudo tee -a /etc/sysctl.d/openai_perf.conf
    echo "net.ipv4.neigh.default.gc_thresh1 = 80000" | sudo tee -a /etc/sysctl.d/openai_perf.conf
    echo "net.ipv4.neigh.default.gc_thresh2 = 90000" | sudo tee -a /etc/sysctl.d/openai_perf.conf
    echo "net.ipv4.neigh.default.gc_thresh3 = 100000" | sudo tee -a /etc/sysctl.d/openai_perf.conf
    # echo "sys.kernel.mm.ksm.run = 1" | sudo tee -a /etc/sysctl.d/openai_perf.conf
    # echo "sys.kernel.mm.ksm.sleep_millisecs = 1000" | sudo tee -a /etc/sysctl.d/openai_perf.conf
    echo "fs.file-max = 2097152" | sudo tee -a /etc/sysctl.d/openai_perf.conf
    sysctl -p
    mkdir -p ~vagrant/dev
    sudo git clone https://github.com/bossjones/debug-tools /usr/local/src/debug-tools
    sudo /usr/local/src/debug-tools/update-bossjones-debug-tools
    sudo chown vagrant:vagrant -Rv ~vagrant
    sudo apt-get install software-properties-common -y
    sudo apt-add-repository ppa:ansible/ansible -y
    sudo apt-get update
    sudo apt-get install ansible -y
    sudo apt-get -y install bison build-essential cmake flex git libedit-dev \
    libllvm6.0 llvm-6.0-dev libclang-6.0-dev python zlib1g-dev libelf-dev
    sudo apt-get -y install luajit luajit-5.1-dev

    cd /usr/local/bin
    wget -O grv https://github.com/rgburke/grv/releases/download/v0.3.1/grv_v0.3.1_linux64
    chmod +x ./grv
    cd -

    ### add packages (both necessary and convenient)
    echo Adding packages...
    apt-get install -y gcc make ncurses-dev libssl-dev bc
    echo Adding packages for perf...
    apt-get install -y flex bison libelf-dev libdw-dev libaudit-dev
    echo Adding packages for perf TUI...
    apt-get install -y libnewt-dev libslang2-dev
    echo Adding packages for convenience...
    apt-get install -y sharutils sysstat bc

    # tigervnc
    # https://www.cyberciti.biz/faq/install-and-configure-tigervnc-server-on-ubuntu-18-04/
    # sudo apt-get install tigervnc-standalone-server tigervnc-xorg-extension tigervnc-viewer -y
    # sudo apt-get install -y ubuntu-gnome-desktop
    # sudo systemctl enable gdm
    # sudo systemctl start gdm

    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab
    sudo swapon --show
    sudo free -h

SCRIPT

Vagrant.configure(2) do |config|
  # set auto update to false if you do NOT want to check the correct additions version when booting this machine
  # config.vbguest.auto_update = true

  config.vm.synced_folder ".", "/srv/ansible-role-tmuxinator", disabled: false

  config_yml[:vms].each do |name, settings|
    # use the config key as the vm identifier
    config.vm.define name.to_s, autostart: true, primary: true do |vm_config|
      config.ssh.insert_key = false
      vm_config.vm.usable_port_range = (2200..2250)

      # This will be applied to all vms

      # set auto_update to false, if you do NOT want to check the correct
      # additions version when booting this machine
      vm_config.vbguest.auto_update = true

      vm_config.vm.box = settings[:box]
      vm_config.disksize.size = '15GB'

      # config.vm.box_version = settings[:box_version]
      vm_config.vm.network 'private_network', ip: settings[:eth1]


      vm_config.vm.hostname = settings[:hostname]

      config.vm.provider 'virtualbox' do |v|
        # make sure that the name makes sense when seen in the vbox GUI
        v.name = settings[:hostname]
        # v.vm.forward_port 5901, 6901

        v.gui = false
        v.customize ['modifyvm', :id, '--memory', settings[:mem]]
        v.customize ['modifyvm', :id, '--cpus', settings[:cpu]]
      end

      hostname_with_hyenalab_tld = "#{settings[:hostname]}.bosslab.com"

      aliases = [hostname_with_hyenalab_tld, settings[:hostname]]

      if Vagrant.has_plugin?('vagrant-hostsupdater')
        puts 'IM HERE BABY'
        config.hostsupdater.aliases = aliases
        vm_config.hostsupdater.aliases = aliases
      elsif Vagrant.has_plugin?('vagrant-hostmanager')
        puts 'IM HERE HONEY'
        vm_config.hostmanager.enabled = true
        vm_config.hostmanager.manage_host = true
        vm_config.hostmanager.manage_guests = true
        vm_config.hostmanager.ignore_private_ip = false
        vm_config.hostmanager.include_offline = true
        vm_config.hostmanager.aliases = aliases
      end

      vm_config.vm.provision 'shell', inline: $configureBox
    end
  end
end

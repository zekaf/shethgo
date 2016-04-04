#!/bin/bash
# 
# AMD-APP-SDK
# http://developer.amd.com/tools-and-sdks/opencl-zone/amd-accelerated-parallel-processing
#
# AMD-ADL-SDK
# http://developer.amd.com/tools-and-sdks/graphics-development/display-library-adl-sdk/
#

# Variables
AMD_APP_SDK_SH="AMD-APP-SDK-v3.0.130.136-GA-linux64.sh"
AMD_APP_SDK_VERSION="3.0"

# script name
BASEN=$(basename $BASH_SOURCE)

# help message
function show_help(){
  echo "usage: ./$BASEN <--amd|--nvidia>"
  exit 1
}

# run command
function evalCMD(){
	CMD=$1
	echo "$CMD"
	eval "$CMD"
}

# replace file values
function replaceVar(){
  VAR1="$1"
  VAR2="$2"
  FILE="$3"
  evalCMD "perl -pi -e 's/$VAR1/$VAR2/g' $FILE"
}

# install AMD-APP-SDK
function installAMD(){
  # remove opensource opencl-dev
  sudo apt-get purge -y $OPENCL
  #URL=""
  if [ ! -d "/opt/AMDAPPSDK-$AMD_APP_SDK_VERSION" ]; then
  	# Control will enter here if /opt/AMDAPPSDK-* doesn't exist. 
	sudo ./$AMD_APP_SDK_SH
  	ln -s /opt/AMDAPPSDK-$AMD_APP_SDK_VERSION /opt/AMDAPP
  	ln -s /opt/AMDAPP/include/CL /usr/include
  	ln -s /opt/AMDAPP/lib/x86_64/* /usr/lib/
  	ldconfig
  	shutdown -r -v +1
  fi
  	sudo apt-get install fglrx-updates
  	sudo aticonfig --adapter=all --initial
  	sudo aticonfig --list-adapters
}

if [ $# != 1 ] ; then
   show_help;
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --amd)
            OPENCL="ocl-icd-opencl-dev xserver-xorg-video-ati"
            installAMD
            shift
            ;;
        --nvidia)
            OPENCL="nvidia-opencl-dev"
            echo "not implemented"
            exit 1
            ;;
        *)
            show_help
            ;;
    esac
    shift
done

# install nodejs
node --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "node is not being recognized as a command; installing ...";
  (exec "./install_nodejs.sh")
fi

# install golang
go version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "go is not being recognized as a command; installing ...";
  (exec "./install_golang.sh")
fi

# update packages
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y software-properties-common

# add ethereum repos
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo add-apt-repository -y ppa:ethereum/ethereum-dev
sudo apt-get update -y

# install additional packages
sudo apt-get install -y git curl build-essential unzip wget ntp

# installation on an Ubuntu EC2 Instance (optional)
#sudo apt-get install -y cloud-utils

# set up time update cronjob
sudo bash -c "cat > /etc/cron.hourly/ntpdate << EOF
#!/bin/sh
pm2 flush
sudo service ntp stop
sudo ntpdate -s ntp.ubuntu.com
sudo service ntp start
EOF"

sudo chmod 755 /etc/cron.hourly/ntpdate

# install pm2
sudo npm install pm2 -g

# install eth-net-intelligence-api
(exec "./install_eth-net-intelligence-api.sh")

# install go-ethereum
(exec "./install_go-ethereum.sh")

# install go-ethereum service
tmpfile=$(mktemp /tmp/ethereum.XXXXXX)
cp resources/ethereum $tmpfile
replaceVar "USER_NAME" "$U" "$tmpfile" &&
sudo cp $tmpfile /etc/init.d/ethereum &&
rm $tmpfile

# configure go-ethereum service to run at startup
sudo update-rc.d ethereum defaults

# username
U=$(whoami)

# instance name
H3=$(./instance_name.sh)

# update net intelligence api configuration
cp resources/app.json $HOME/eth-net-intelligence-api/ && 
replaceVar "I_NAME" "$H3" "$HOME/eth-net-intelligence-api/app.json" &&
replaceVar "C_DETAILS" "${U}\@${H3}" "$HOME/eth-net-intelligence-api/app.json" && 

exit 0

sudo mkfs.ext4 /dev/xvdh
sudo mkdir /media/wordlists
sudo mount /dev/xvdh /media/wordlists
echo "Here I would download my wordlists..."
sudo apt update -y
sudo apt install hashcat -y
sudo apt install john -y
sudo apt install make -y
sudo apt install gcc -y
sudo apt install pkg-config -y
VERSION=410.104
wget "http://us.download.nvidia.com/tesla/${VERSION}/NVIDIA-Linux-x86_64-$VERSION.run" -O /tmp/nvidia_install.run
chmod +x /tmp/nvidia_install.run
sudo /tmp/nvidia_install.run -s
rm /tmp/nvidia_install.run 

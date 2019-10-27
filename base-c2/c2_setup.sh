#!/bin/bash
# Just a PoC right now...still WIP
sudo export APT_LISTCHANGES_FRONTEND=cat && sudo apt update && sudo apt upgrade -y && sudo apt autoclean -y && sudo apt autoremove -y
sudo apt install empire -y

#!/usr/bin/env bash

# This file is part of pi-frontend.
#
# pi-frontend is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pi-frontend is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with pi-frontend.  If not, see <https://www.gnu.org/licenses/>.

set -e

MYTHTV_BRANCH=fixes/35

sudo apt-get update
sudo apt-get install -y \
    lirc \
    || true

# Pi 5 graphics for MythTV
sudo apt-get install -y \
    mesa-vulkan-drivers mesa-utils vulkan-tools \
    || true

if [ ! -f /usr/bin/mythfrontend ]; then
    mkdir -p ~/build
    git clone --branch "${MYTHTV_BRANCH}" https://github.com/MythTV/packaging.git ~/build/packaging
    cd ~/build/packaging/deb
    ./build-debs.sh "${MYTHTV_BRANCH}"
    dpkg-scanpackages -m . > Packages
    echo "deb [trusted=yes] file://${HOME}/build/packaging/deb ./" | sudo tee /etc/apt/sources.list.d/mythtv.list
    sudo apt-get update
    sudo apt-get install -y mythtv-frontend
    sudo usermod -a -G mythtv "${USER}"
    cd -
fi

mkdir -p ~/.config/autostart
ln -s /usr/share/applications/mythtv.desktop ~/.config/autostart/mythtv.desktop

sudo cp 00-Streamzap_PC_Remote.conf /etc/lirc/lircd.conf.d/
sudo cp streamzap-blacklist.conf /etc/modprobe.d/

# Set driver to 'default'
sudo sed -i -e 's/devinput/default/' /etc/lirc/lirc_options.conf
# Set device to '/dev/lirc0'
sudo sed -i -e 's/auto/\/dev\/lirc0/' /etc/lirc/lirc_options.conf

mkdir -p ~/.mythtv
mkdir -p ~/.lirc
cp lircrc ~/.lirc/mythtv
ln -s ~/.lirc/mythtv ~/.mythtv/lircrc
echo 'include ~/.lirc/mythtv' >> ~/.lircrc
# ~/.mythtv/config.xml needed to connect to backend with DB credentials

echo "Successfully configured MythTV."

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

MYTHTV_BRANCH=fixes/36
BUILDDEST="${HOME}/proj/build"

sudo apt-get update
sudo apt-get install -y \
    lirc \
    || true

# Pi 5 graphics for MythTV
sudo apt-get install -y \
    cmake \
    mesa-vulkan-drivers mesa-utils vulkan-tools \
    || true

# Compile dependencies
sudo apt-get install -y \
    git ansible \
    || true

if [ ! -f /usr/bin/mythfrontend ]; then
    rm -fr ~/build ~/.buildrc
    echo "BUILD_METHOD=cmake" | tee ~/.buildrc
    echo "BUILDDEST=${BUILDDEST}" | tee -a ~/.buildrc
    echo "MYTHTV_SOURCE_BRANCH=${MYTHTV_BRANCH}" | tee -a ~/.buildrc
    mkdir -p ~/build
    git clone https://github.com/MythTV/ansible ~/build/ansible
    cd ~/build/ansible
    ./mythtv.yml --limit=localhost  # requires manual entry of password
    git clone --branch "${MYTHTV_BRANCH}" https://github.com/MythTV/mythtv.git ~/build/mythtv
    git clone --branch "${MYTHTV_BRANCH}" https://github.com/MythTV/packaging.git ~/build/packaging
    cd ~/build/mythtv/mythtv
    ~/build/packaging/deb-light/build_package.sh  # about 30mins on RPI5
    #plugins may not be needed
    #cd ../mythplugins
    #~/build/packaging/deb-light/build_package.sh  # about 30mins on RPI5
    cd ../..
    dpkg-scanpackages -m . > Packages
    echo "deb [trusted=yes] file://${HOME}/build ./" | sudo tee /etc/apt/sources.list.d/mythtv.list
    sudo chown _apt ./*.deb
    sudo apt-get update
    sudo apt-get install -y mythtv-light
    #sudo apt-get install -y mythplugins-light
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

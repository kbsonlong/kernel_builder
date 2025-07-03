#!/usr/bin/env bash

VERSION=$(grep 'Kernel Configuration' < config | awk '{print $3}')

# add deb-src to sources.list
sed -i "/deb-src/s/# //g" /etc/apt/sources.list

# install dep
apt update
apt install -y wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev git
apt build-dep -y linux

# change dir to workplace
cd "${GITHUB_WORKSPACE}" || exit

# download kernel source
git clone https://gitee.com/anolis/cloud-kernel.git
git clone --depth 1 -b 6.6.88-4.1.1 https://gitee.com/anolis/cloud-kernel.git
cd cloud-kernel || exit

# copy config file
# cp ../config .config
# sed -i 's/5.15.0-84-custom/6.6.88-4.1.1/g' .config
make anolis_defconfig

# disable DEBUG_INFO to speedup build
# scripts/config --disable DEBUG_INFO
# apply patches
# shellcheck source=src/util.sh
# source ../patch.d/*.sh

# build deb packages
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
make deb-pkg -j"$CPU_CORES"
if [ $? != 0 ];then
  make -j"$CPU_CORES"
fi

# move deb packages to artifact dir
cd ..
rm -rfv *dbg*.deb
mkdir "artifact"
mv ./*.deb artifact/

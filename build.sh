#!/bin/bash -e
#
# Copyright (c) 2010 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

DIR=$PWD

CCACHE=ccache

unset BISECT

mkdir -p ${DIR}/git/
mkdir -p ${DIR}/dl/
mkdir -p ${DIR}/deploy/

ARCH=$(uname -m)

if test "-$ARCH-" = "-armv7l-" || test "-$ARCH-" = "-armv5tel-"
then
 #using native gcc
 CC=
else
 #using Cross Compiler
 CC=arm-linux-gnueabi-
fi

function git_bisect {

echo ""
echo "This is inverted, trying to find 256MB fix"
echo ""

git bisect start
echo "git bisect bad v2010.12"
git bisect bad v2010.12
echo "git bisect good 6d8d4ef994a7c46e34b5fe53b1af7aa4f78192bf"
git bisect good 6d8d4ef994a7c46e34b5fe53b1af7aa4f78192bf


}

function git_bisect_invalid {

git bisect start
echo "git bisect bad v2010.12"
git bisect bad v2010.12
echo "git bisect good v2010.09"
git bisect good v2010.09

echo "unbuildable"
echo "git bisect skip 4a8fd13af82b7b37099fea3d12ea52e5bcc151a5"
echo "git bisect skip 9710504d200599a6e7e7ac0046adca43cfccaf0f"
echo "git bisect skip 0693923cd240f5d401be0a53cddcf0fb1d9ad9d3"
echo "git bisect skip 92d5ecba47feb9961c3b7525e947866c5f0d2de5"

git bisect skip 4a8fd13af82b7b37099fea3d12ea52e5bcc151a5
git bisect skip 9710504d200599a6e7e7ac0046adca43cfccaf0f
git bisect skip 0693923cd240f5d401be0a53cddcf0fb1d9ad9d3
git bisect skip 92d5ecba47feb9961c3b7525e947866c5f0d2de5

echo "git bisect bad b18815752f3d6db27877606e4e069e3f6cfe3a19"
git bisect bad b18815752f3d6db27877606e4e069e3f6cfe3a19
echo "git bisect good 59a50d2de1f9c037166a6f86e6e6cdc1670aa155"
git bisect good 59a50d2de1f9c037166a6f86e6e6cdc1670aa155
echo "git bisect good 084c4c1bc10ef7abd64eebaf4c0a559409c82ddb"
git bisect good 084c4c1bc10ef7abd64eebaf4c0a559409c82ddb
echo "git bisect good c56ded6a6e8962272c8dd893cac49fd7f60fb9d1"
git bisect good c56ded6a6e8962272c8dd893cac49fd7f60fb9d1
echo "git bisect bad 3ba8bf7c6d6c09b9823b08b03d2d155907313238"
git bisect bad 3ba8bf7c6d6c09b9823b08b03d2d155907313238
echo "git bisect good 083d506937002f2795c80fe0c3ae194ad2c3d085"
git bisect good 083d506937002f2795c80fe0c3ae194ad2c3d085
echo "git bisect bad 6d8d4ef994a7c46e34b5fe53b1af7aa4f78192bf"
git bisect bad 6d8d4ef994a7c46e34b5fe53b1af7aa4f78192bf
echo "git bisect bad c3d3a5418de3ce01248bb556b4bd3d293c4f9f1e"
git bisect bad c3d3a5418de3ce01248bb556b4bd3d293c4f9f1e

}

function at91_loader {
echo ""
echo "Starting AT91Bootstrap build"
echo ""

if ! ls ${DIR}/dl/AT91Bootstrap${AT91BOOTSTRAP}.zip >/dev/null 2>&1;then
wget --directory-prefix=${DIR}/dl/ ftp://www.at91.com/pub/at91bootstrap/AT91Bootstrap${AT91BOOTSTRAP}.zip
fi

rm -rfd ${DIR}/Bootstrap-v${AT91BOOTSTRAP} || true
unzip -q ${DIR}/dl/AT91Bootstrap${AT91BOOTSTRAP}.zip

cd ${DIR}/Bootstrap-v${AT91BOOTSTRAP}
sed -i -e 's:/usr/local/bin/make-3.80:/usr/bin/make:g' go_build_bootstrap.sh
sed -i -e 's:/opt/codesourcery/arm-2007q1/bin/arm-none-linux-gnueabi-:'${CC}':g' go_build_bootstrap.sh
./go_build_bootstrap.sh

cd ${DIR}/

}

function build_omap_xloader {

echo ""
echo "Starting x-loader build"
echo ""

if ! ls ${DIR}/git/x-loader >/dev/null 2>&1;then
cd ${DIR}/git/
git clone git://gitorious.org/x-loader/x-loader.git
fi

cd ${DIR}/git/x-loader
make ARCH=arm distclean
git pull
GIT_VERSION=$(git rev-parse HEAD)
GIT_MON=$(git show HEAD | grep Date: | awk '{print $3}')
GIT_DAY=$(git show HEAD | grep Date: | awk '{print $4}')
make ARCH=arm distclean &> /dev/null
make ARCH=arm CROSS_COMPILE=${CC} ${XLOAD_CONFIG}
echo "Building x-loader"
make ARCH=arm CROSS_COMPILE="${CCACHE} ${CC}" ift

mkdir -p ${DIR}/deploy/${BOARD}
cp -v MLO ${DIR}/deploy/${BOARD}/MLO-${BOARD}-${GIT_MON}-${GIT_DAY}-${GIT_VERSION}

make ARCH=arm distclean &> /dev/null
git checkout master
cd ${DIR}/

echo ""
echo "x-loader build completed"
echo ""

}

function build_u-boot {

echo ""
echo "Starting u-boot build"
echo ""

if ! ls ${DIR}/git/u-boot >/dev/null 2>&1;then
cd ${DIR}/git/
git clone git://git.denx.de/u-boot.git
fi

cd ${DIR}/git/u-boot
make ARCH=arm CROSS_COMPILE=${CC} distclean &> /dev/null
git reset --hard
git fetch
git checkout master
git pull
git branch -D u-boot-scratch || true

if [ "${UBOOT_GIT}" ] ; then
git checkout ${UBOOT_GIT} -b u-boot-scratch
else
git checkout ${UBOOT_TAG} -b u-boot-scratch
fi

#patch -p1 < "${DIR}/patches/<>"
#git add .
#git commit -a -m 'patchset'

if [ "${BISECT}" ] ; then
git_bisect
fi

git describe
GIT_VERSION=$(git rev-parse HEAD)

#cat ${DIR}/git/u-boot/fs/fat/fat.c | grep "LINEAR_PREFETCH_SIZE," && git am ${DIR}/patches/0001-FAT-buffer-overflow-with-FAT12-16.patch
##cat ${DIR}/git/u-boot/arch/arm/config.mk | grep "CONFIG_SYS_ARM_WITHOUT_RELOC" && git am ${DIR}/patches/0001-Drop-support-for-CONFIG_SYS_ARM_WITHOUT_RELOC.patch
#cat ${DIR}/git/u-boot/arch/arm/cpu/armv7/omap-common/timer.c | grep "DECLARE_GLOBAL_DATA_PTR;" || git am ${DIR}/patches/0001-OMAP-Timer-Replace-bss-variable-by-gd.patch
#cat ${DIR}/git/u-boot/arch/arm/include/asm/global_data.h | grep "lastinc" || git am ${DIR}/patches/0001-arm920t-at91-timer-replace-bss-variables-by-gd.patch
#cat ${DIR}/git/u-boot/arch/arm/include/asm/global_data.h | grep "#ifdef CONFIG_ARM" || git am ${DIR}/patches/0001-ARM-make-timer-variables-in-gt_t-available-for-all-A.patch

make ARCH=arm CROSS_COMPILE=${CC} ${UBOOT_CONFIG}
echo "Building u-boot"
time make ARCH=arm CROSS_COMPILE="${CCACHE} ${CC}"

mkdir -p ${DIR}/deploy/${BOARD}
cp -v u-boot.bin ${DIR}/deploy/${BOARD}/u-boot-${UBOOT_TAG}-${BOARD}-${GIT_VERSION}

make ARCH=arm CROSS_COMPILE=${CC} distclean &> /dev/null
git checkout master
cd ${DIR}/

echo ""
echo "u-boot build completed"
echo ""

}

function cleanup {
unset UBOOT_TAG
unset UBOOT_GIT
unset AT91BOOTSTRAP
}

#AT91Sam Boards
function at91sam9xeek {
cleanup

BOARD="at91sam9xeek"
AT91BOOTSTRAP="1.16"
at91_loader
}

#Omap3 Boards
function beagleboard {
cleanup

BOARD="beagleboard"
XLOAD_CONFIG="omap3530beagle_config"
build_omap_xloader

UBOOT_CONFIG="omap3_beagle_config"
UBOOT_TAG="v2010.12"
#BISECT=1
#UBOOT_GIT="2956532625cf8414ad3efb37598ba34db08d67ec"
build_u-boot

UBOOT_CONFIG="omap3_beagle_config"
UBOOT_TAG="v2010.09"
#BISECT=1
#UBOOT_GIT="2956532625cf8414ad3efb37598ba34db08d67ec"
build_u-boot

}

function igep0020 {
cleanup

BOARD="igep0020"
#posted but not merged
#XLOAD_CONFIG="igep0020_config"
#build_omap_xloader

UBOOT_CONFIG="igep0020_config"
UBOOT_TAG="v2010.12"
#UBOOT_GIT="2956532625cf8414ad3efb37598ba34db08d67ec"
build_u-boot
}

#Omap4 Boards
function pandaboard {
cleanup

BOARD="pandaboard"
XLOAD_CONFIG="omap4430panda_config"
build_omap_xloader

UBOOT_CONFIG="omap4_panda_config"
UBOOT_TAG="v2010.12"
#UBOOT_GIT="2956532625cf8414ad3efb37598ba34db08d67ec"
build_u-boot
}

#at91sam9xeek
beagleboard
igep0020
pandaboard


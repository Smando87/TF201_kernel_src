#!/bin/sh
#IMPOSTO DIRECTORY DI LAVORO
export KERNELDIR=`readlink -f .`
export INITRAMFS_SOURCE=`readlink -f $KERNELDIR/ramfs`
export PARENT_DIR=`readlink -f ..`
DATE=`date +%Y%m%d-%H%M`
LOGFILE=$KERNELDIR/build-$DATE.log
export CONFIG_DEFAULT_HOSTNAME=smandovm1
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=/home/simone/Desktop/android-ndk-r7b/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86/bin/arm-linux-androideabi-

# input: 
# $1 stringa di log
# $2 tipo di log (v=video, f=file, a=v+f)
log(){
	if [ $2 == "v" ]; then
		echo $1
	fi
	if [ $2 == "f" ]; then
		echo $1 >> $LOGFILE
	fi
	if [ $2 == "a" ]; then
		echo $1 >> $LOGFILE
		echo $1
	fi	
}

clean(){
	rm -Rf $KERNELDIR/build*.log
	rm -Rf $KERNELDIR/arch/$ARCH/boot/zImage	
}

clean
echo "Build log : $LOGFILE"

if [ "${1}" != "" ];then
  export KERNELDIR=`readlink -f ${1}`
fi


INITRAMFS_TMP="/tmp/initramfs-source"

if [ ! -f $KERNELDIR/.config ];
then
  make tegra_smando_defconfig
fi

. $KERNELDIR/.config


rm -rf $INITRAMFS_TMP
rm -rf $INITRAMFS_TMP.cpio
mkdir $INITRAMFS_TMP





log "Compilo moduli aggiuntivi..." a
cd $KERNELDIR/
# compilo solo i moduli...
( nice -n 10 make -j4 modules || exit 1 ) >> $LOGFILE 2>> $LOGFILE

#ls -lah $KERNELDIR/arch/$ARCH/boot/zImage

log "Preparo l initramfs compresso(comprensivo di moduli)..." a

(
rm -rf $INITRAMFS_TMP
cp -ax $INITRAMFS_SOURCE $INITRAMFS_TMP
find $INITRAMFS_TMP -name .git -exec rm -rf {} \;
rm -rf $INITRAMFS_TMP/.hg
find -name '*.ko' -exec cp -av {} $INITRAMFS_TMP/lib/modules/ \;

cd $INITRAMFS_TMP
find | fakeroot cpio -H newc -o > $INITRAMFS_TMP.cpio 2>/dev/null
ls -lh $INITRAMFS_TMP.cpio
cd -
) >> $LOGFILE 2>> $LOGFILE

log "Compilo il kernel+initramfs..." a
(

nice -n 10 make -j3 zImage CONFIG_INITRAMFS_SOURCE="$INITRAMFS_TMP.cpio" || exit 1

ls -lah $KERNELDIR/arch/$ARCH/boot/zImage
) >> $LOGFILE 2>> $LOGFILE

ls -lah $KERNELDIR/arch/$ARCH/boot/zImage
#TODO: ora bisogna creare il file .blob flashabile tramite partizione /stagin




#!/bin/sh
# author: Smando
# mail: smando@gmail.com
# build.sh 0.9

#NOTA: L'initramfs è compreso nel kernel! dunque zImage == boot.img

#NOTA: recovery.img non è compresa nel kernel!!

#NOTA: Per ora flashare con "dd if=/sdcard/boot.img of=/dev/block/mmcblk0 seek=3968 bs=4096 count=2048"

#TODO: dal boot.img bisogna creare il file .blob signato flashabile tramite partizione /stagin in CWM (solo kernel asus) 


#VARIABILI
export KERNELDIR=`readlink -f .`
export INITRAMFS_SOURCE=`readlink -f $KERNELDIR/ramfs`
export PARENT_DIR=`readlink -f ..`
INITRAMFS_TMP="/tmp/initramfs-source"
MODULI_TMP="/tmp/moduli-compilati"
DATE=`date +%Y%m%d-%H%M`
LOGFILE=$KERNELDIR/build-$DATE.log
export CONFIG_DEFAULT_HOSTNAME=smandovm1
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=$PARENT_DIR/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86/bin/arm-linux-androideabi-


# log($1,$2) 
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

#Pulisce log+initramfs+moduli+zImage
clean(){
	rm -Rf $KERNELDIR/build*.log
	rm -Rf $KERNELDIR/arch/$ARCH/boot/zImage
	rm -Rf $KERNELDIR/boot.img
	
	rm -rf $INITRAMFS_TMP
	rm -rf $INITRAMFS_TMP.cpio
	rm -rf $MODULI_TMP
	mkdir $INITRAMFS_TMP	
}


init(){
	echo "Build log : $LOGFILE"
	touch $LOGFILE
	(gnome-terminal -t $LOGFILE --tab-with-profile=Default -e "tail -f $LOGFILE" &)

	if [ ! -f $KERNELDIR/.config ];
	then
  		make tegra_smando_defconfig
	fi
	. $KERNELDIR/.config
}

compila_moduli(){
	init
	log "Compilo moduli aggiuntivi..." a
	cd $KERNELDIR/
	# compilo solo i moduli...
	( nice -n 10 make -j4 modules || exit 1 ) >> $LOGFILE 2>> $LOGFILE

	#ls -lah $KERNELDIR/arch/$ARCH/boot/zImage
}

copia_moduli(){
	log "Copio i moduli in $MODULI_TMP..." a
	mkdir $MODULI_TMP

	find -name '*.ko' -exec cp -av {} $MODULI_TMP/ \; >> $LOGFILE 2>> $LOGFILE
}

crea_initramfs(){
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
}

compila_kernel(){
	log "Compilo il kernel+initramfs..." a
	(

	nice -n 10 make -j3 zImage CONFIG_INITRAMFS_SOURCE="$INITRAMFS_TMP.cpio" || exit 1

	ls -lah $KERNELDIR/arch/$ARCH/boot/zImage
	) >> $LOGFILE 2>> $LOGFILE

	mv $KERNELDIR/arch/$ARCH/boot/zImage $KERNELDIR/boot.img
}

usage(){

 echo "		build.sh moduli -> compila i moduli"
 echo "		build.sh moduli+installa -> compila i moduli e gli installa"
 echo "		build.sh kern -> compila il kernel+moduli+initramfs" 
 echo "		build.sh kern+flash -> compila il kernel+moduli+initramfs e flasha il kernel"
 echo "		build.sh pulisci -> pulisci tutto"
}

build_all(){
	
	compila_moduli
	crea_initramfs
	compila_kernel
}


installa_moduli(){
	log "Installo i moduli sul TF201..." a
	adb remount
	adb push $MODULI_TMP/* /data/local/modules/
}

puliscitutto(){
	clean
	make clean	
}

flash_kernel(){
		log "Riavvio in recovery per flash kernel..." a
		adb reboot recovery
		log "Attendo 20s..." a
		sleep 20
		log "Copio boot.img su sdcard..." a
		adb push $KERNELDIR/boot.img /sdcard/boot.img
		log "Flasho tramite dd..." a
		adb shell dd if=/sdcard/boot.img of=/dev/block/mmcblk0 seek=3968 bs=4096 count=2048
		log "Fatto!?Riavvio..." a
		adb reboot
	

}
case $1 in
	moduli ) clean
		 compila_moduli
		 copia_moduli
	;;
	moduli+installa) clean
		 	 compila_moduli
		 	 copia_moduli
			 installa_moduli
	;;
	kern )  clean
		build_all
	;;
	kern+flash ) clean
		     build_all
		     flash_kernel	
	;;
	pulisci ) puliscitutto
	;;
	*) usage
	;;

esac

log "Fine" a






#!/bin/bash

MY_NAME=`basename "$0"`
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`
MY_IMG="dockerapktools"
MY_CONT="apksigner"

function sign() {
	cd /project
	echo "Processing apk-files: /project/req/*.apk"
	for APK in /project/req/*.apk
		do 
			test -f "${APK}" || continue
			zip  -f "${APK}" /project/assets/org.linphone.core/share/linphone/rootca.pem
			CAPK="./signed/$(basename ${APK})-mod.apk"
			zipalign -p4 ${APK} ${CAPK}
			zipalign -c4 ${CAPK}
			apksigner sign --ks keystore/mwejavkeys ${CAPK}
			apksigner verify ${CAPK}
		done
}


function build_signer_factory() {
	docker build --tag ${MY_IMG} .
}

function setup_signer_factory() {
	docker create -it -v ${MY_PATH}:/project --name "${MY_CONT}" "${MY_IMG}" /bin/bash
}

function enter_signer_factory() {
	docker start -ai "${MY_CONT}" 
}

function clean_signer_factory() {
	docker stop "${MY_CONT}" 
	docker rm "${MY_CONT}" 
}

function print_help() {
	echo "Usage: ${MY_NAME} [ setup | batch | interactive | sign ]" 
	echo "   or: ${MY_NAME} [ clean ]" 
	echo "   or: ${MY_NAME} [ build ]" 
	echo "   or: ${MY_NAME} [ help ]" 
}


case "$1" in

	sign)
		sign ;;

	build)
		build_signer_factory ;;

	setup)
		setup_signer_factory ;;

	batch)
		batchsign_signer_factory ;;

	interactive)
		enter_signer_factory ;;

	clean)
		clean_signer_factory ;;

	*)
		print_help ;;

esac
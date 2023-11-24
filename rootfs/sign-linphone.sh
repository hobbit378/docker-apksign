#!/bin/bash

# set defaults if no explicit parameters given
BASE_DIR=${BASE_DIR:=${PWD}}
KSSTORE=${KSSTORE:="${BASE_DIR}/keys/_default"}
KSPWD=${KSPWD:="stdin"}

function sign() {


	if [ ! -r "${KSSTORE}" ] ; then
		echo "No valid keystore found:" 
		echo "   KSSTORE='${KSSTORE}'" 
		echo "EXIT."
	fi

	echo " => Processing '${APK}'"

	echo "  - Clonig input file ..."
	shopt -s nocasematch
	CLONE_FILE=${OUT_DIR}/$(basename ${APK})
	CLONE_FILE="${CLONE_FILE%.apk}.tmp"
	cp -v "${APK}" "${CLONE_FILE}"
	shopt -u nocasematch

	echo "  - Deleting 'META-INF/*' directory ..."
	zip -d "${CLONE_FILE}" 'META-INF/MANIFEST.MF' 'META-INF/*.SF' 'META-INF/*.RSA'

	echo "  - Updating certificate resources ..."
	zip  -f "${CLONE_FILE}" "assets/org.linphone.core/share/linphone/rootca.pem"

	echo "  - Aligning archive ..."
	OUT_FILE=${CLONE_FILE%.tmp}.mod.apk
	zipalign -v 4 "${CLONE_FILE}" "${OUT_FILE}"

	echo "  - Verify alignment ..."
	zipalign -c 4 "${OUT_FILE}"

	echo "  - Sign package ..."
	apksigner sign --ks "${KSSTORE}" --ks-pass "${KSPWD}" "${OUT_FILE}"

	echo "  - Verify signature ..."
	apksigner verify "${CAPK}"

	echo "  - Tidy up ..."
	rm "${CLONE_FILE}"

	echo "    DONE"
	
}

function sign_batch() {
	echo "Processing apk-files with filter: ${IN_DIR}/*.apk"
	for APK in ${IN_DIR}/*.apk
		do sign "${APK}"
	done
}

function startup() {
	while getopts ":cd:Di:k:p:" OPT; do
		case $OPT in
		
		'd')
			# set explicit BASE_DIR path
			test -d ${OPTARG} && BASE_DIR="${OPTARG}" || exit ;;
		
		'D')
			# turn on debugging
			set -x ;;
		
		'i')
			# set explicit IN_DIR directory path containing APKs to sign
			test -d ${OPTARG} && IN_DIR="${OPTARG}" || exit ;;
		
		'k')
			# set explicit KSSTORE file path to keystore
			test -r ${OPTARG} && KSSTORE="${OPTARG}" || exit ;;
		
		'p')
			# set password
			KSPWD="${OPTARG}" ;;

		'c')
			# create  keystore, set path and continue
			read -p "Please enter alias for to be created keystore > " -i "my-key-alias" ksalias
			read -p "Please enter path for to be created keystore > " -i "${KSSTORE}" kspath
			keytool -genkey -v -keystore ${kspath} -alias ${ksalias} -keyalg RSA -keysize 2048 -validity 10000
			test -r ${kspath} && KSSTORE="${kspath}" || exit ;;
		
		':')
			echo "Option '-${OPTARG}' is missing a required argument!"
			exit ;; 

		*)
			echo "ToDo: There is someting wrong with an option"
			exit ;;
		esac
	done
}

startup

if [ "$BATCHMODE" == "TRUE" ] ; then
	if [ -d $1 ] ; then
		IN_DIR="$1"
	fi
	IN_DIR=${IN_DIR:="${BASE_DIR}/in"}
	OUT_DIR=${OUT_DIR:="${BASE_DIR}/out"}
	sign_batch
else
	sign
fi
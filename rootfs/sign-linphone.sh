#!/bin/bash

# set defaults if no explicit parameters given
BASE_DIR=${BASE_DIR:=${PWD}}
KSSTORE=${KSSTORE:="${BASE_DIR}/keys/_default"}
KSPWD=${KSPWD:="stdin"}

function print_help(){

echo "
$0	[-d BASE_DIR ] [-i IN_DIR ] [-k KSSTORE ] [-p PWD ] [-D] <INFILE>

$0 -c
$0 -h

	-d BASE_DIR		set explicit BASE_DIR path (default: '${BASE_DIR}')
	-i IN_DIR		set explicit IN_DIR path containing APKs to sign (default: '${IN_DIR}')
	-k KSSTORE		set explicit KSSTORE path (default: '${KSSTORE}')
	-p PASSWORD		set password for KSSTORE (default: '${KSPWD}')
	-c			create  keystore, set path and continue

	-h			print help

	-D			turn on additional debugging output

	"
}


function sign() {

	if [ ! -r "$1" ] ; then
		echo "Error: Input File '$1' not found/not readable"
		print_help
		echo "Exit"
		exit 1
	else
		APK=${1}
	fi

	if [ ! -r "${KSSTORE}" ] ; then
		echo "Error: Keystore File '${KSSTORE}' not found/not readable" 
		echo "Exit"
		exit 1
	fi

	echo " => Processing '${APK}'"

	echo "  - Clonig input file ..."
	CLONE_FILE=${APK}.clone
	cp -v "${APK}" "${CLONE_FILE}"

	echo "  - Deleting 'META-INF/*' directory ..."
	zip -d "${CLONE_FILE}" 'META-INF/MANIFEST.MF' 'META-INF/*.SF' 'META-INF/*.RSA'

	# TODO Remove/Change in order to adjust to sign other files 
	echo "  - Updating certificate resources ..."
	zip  -f "${CLONE_FILE}" "assets/org.linphone.core/share/linphone/rootca.pem"

	echo "  - Aligning archive ..."
	OUT_FILE=${${CLONE_FILE}%.clone}.align
	zipalign -v 4 "${CLONE_FILE}" "${OUT_FILE}"

	echo "  - Verify alignment ..."
	zipalign -c 4 "${OUT_FILE}"

	echo "  - Sign package ..."
	apksigner sign --ks "${KSSTORE}" --ks-pass "${KSPWD}" "${OUT_FILE}"

	echo "  - Verify signature ..."
	apksigner verify "${OUT_FILE}"

	SIGNED_FILE=${${OUT_FILE}%.align}.signed
	cp -v "${OUT_FILE}" "${SIGNED_FILE}" 

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

		'h')
			print_help ;;
		
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
	sign "$1"
fi
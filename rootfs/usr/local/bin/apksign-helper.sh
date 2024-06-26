#!/bin/bash

# set defaults if no explicit parameters given
KSTORE=${KSTORE:="${PROJECT_HOME}/kstore"}
KSPWD=${KSPWD:="stdin"}
PATCH=${PATCH:=""}

function usage() 
{

cat <<EOF
$0	-c | -h
	[-k KSTORE ] [-p PWD ] [-v] <INFILE/INDIR>

	-c				create  keystore, set path and continue
	-k KSTORE		set explicit KSTORE path (default: '${KSTORE}')
	-p PASSWORD		set password for KSTORE (default: '${KSPWD}')
	-m PATCH		'modify': apply selected patch to apk, e.g. 'Linphone'
	-v				turn on bash script debugging output

	-h				print usage information

When run within a docker environment make sure to mount project directory on host to container directory ${PROJECT_HOME}
e.g.

	podman run -it --rm -v <YOURHOSTPROJECTDIR>:${PROJECT_HOME} <IMAGENAME> $0 [OPTIONS] <INFILE/INDIR> 

EOF

if [ -n "$1" ] ; then
	echo "$1"
	exit 1
else
	exit
fi

}

function create_keystore()
{
	read -p "Please enter alias for to be created keystore > " -i "my-key-alias" ksalias
	read -p "Please enter path for to be created keystore > " -i "${KSTORE}" kspath
	keytool -genkey -v -keystore ${kspath} -alias ${ksalias} -keyalg RSA -keysize 2048 -validity 10000
	test -r ${kspath} && KSTORE="${kspath}" || exit
}

function apply_patch_Linphone()
{
	# TODO Remove/Change in order to adjust to sign other files 
	echo "  - Updating Linphone Root Certificate resources ..."
	zip  -f "$1" "assets/org.linphone.core/share/linphone/rootca.pem"
}

function sign() {

	if [ ! -r "$1" ] ; then
		echo "Error: Input File '$1' not found/not readable."
		exit 1
	else
		APK=${1}
	fi

	if [ ! -r "${KSTORE}" ] ; then
		echo "Error: Keystore File '${KSTORE}' not found/not readable. Maybe you need to create it first" 
		exit 1
	fi

	echo " => Processing '${APK}'"

	echo "  - Cloning & moving input file ..."
	CLONE_FILE=${APK%.apk}.tmp
	cp -v "${APK}" "${CLONE_FILE}"
	ORIGN_FILE=${APK%.apk}.orig
	mv -v "${APK}" "${ORIGN_FILE}"

	echo "  - Deleting old 'META-INF/*' directory ..."
	zip -d "${CLONE_FILE}" 'META-INF/MANIFEST.MF' 'META-INF/*.SF' 'META-INF/*.RSA'

	if [ -n "${PATCH}" ] ; then
		apply_patch_${PATCH} ${CLONE_FILE}
	fi

	echo "  - Adjusting APK archive alignment ..."
	OUT_FILE=${CLONE_FILE}-aligned
	if zipalign -v 4 "${CLONE_FILE}" "${OUT_FILE}" ; then
		echo "  - Verifying alignment ..."
		zipalign -c 4 "${OUT_FILE}"
		mv -vf "${OUT_FILE}" "${CLONE_FILE}"
	else
		echo "  - Error while trying to allign ..."
		exit 1
	fi

	echo "  - Signing package ..."
	apksigner sign --ks "${KSTORE}" --ks-pass "${KSPWD}" "${CLONE_FILE}"

	echo "  - Verifying signature ..."
	apksigner verify "${CLONE_FILE}"

	echo "  - Moving package ..."
	mv -v "${CLONE_FILE}" "${APK}" 

	echo "    DONE"
	
}

function sign_batch() {
	echo "Processing apk-files with filter: ${1}/*.apk"
	for APK in ${1}/*.apk
		do sign ${APK}
	done
}

function startup() {
	while getopts ":ck:p:m:hv" OPT; do
		case $OPT in
		
		'k')
			# set explicit KSTORE file path to keystore
			test -r ${OPTARG} && KSTORE="${OPTARG}" || usage "ERROR: Keystore '${OPTARG}' does not exist/not readable!"
			;;
		
		'p')
			# set password
			KSPWD="${OPTARG}"
			;;
		
		'm')
			# set patch to apply
			PATCH="${OPTARG}"
			;;

		'c')
			# create  keystore
			create_keystore
			exit
			;;

		'h')
			usage
			;;
		
		'v')
			# turn on debugging
			set -x
			;;
		
		':')
			usage "ERROR: Option '-${OPTARG}' is missing a required argument!"
			;; 

		*)
			usage "ERROR: No such option!"
			;;

		esac
	done

	shift $((OPTIND-1))

	for file in $* ; do
		if [ -f ${file} ] ; then 
			sign ${file}
		elif [ -d ${file} ] ; then
			sign_batch ${file}
		fi
	done 

}

startup $*

# reset debug flag if any
set +x

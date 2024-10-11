#!/bin/bash

function apply_patch_Linphone()
{
	# TODO Remove/Change in order to adjust to sign other files 
	echo "  - Updating Linphone Root Certificate resources ..."
    cd /usr/local/share/apkps/patch_linphone
	zip  -f "$1" "assets/org.linphone.core/share/linphone/rootca.pem"
    cd -
}

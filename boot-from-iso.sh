#!/usr/bin/env bash
set -euoE pipefail

usage() 	{
	echo "${@}"
	echo "Usage: $0 [-d] -r idrac-hostname -u user -p password -i http://iso-url" 1>&2; 
	exit 1; 
}

if [[ $# -lt 8 ]]; then
	usage "Insufficient number of parameters"
fi

while getopts ":r:u:p:i:d" o; do
	case "${o}" in
		r)
			HOST=${OPTARG};;
		u)
			USER=${OPTARG};;
		p)
			PASSWORD=${OPTARG};;
		i)
			ISO_URL=${OPTARG}
			[[ $ISO_URL =~ http://.* ]] || usage "Iso should be with http prefix"
			;;
		d)	DELETE="TRUE";;
		*)
			usage;;
	esac
done
shift $((OPTIND-1))

echo HOST = $HOST
echo USER = $USER
echo PASSWORD = $PASSWORD
echo ISO_URL = $ISO_URL

if [ $DELETE ]; then
echo '******* Initializing virtual disk to ensure clean boot to ISO'
/opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD storage init:Disk.Virtual.0:RAID.Integrated.1-1 -speed fast 
/opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD jobqueue create RAID.Integrated.1-1 -s TIME_NOW 

fi

if ! curl --output /dev/null --silent --head --fail "$ISO_URL"; then
	  usage "******* ISO does not exist in the provided url: $ISO_URL"
fi

echo '******* Disconnecting existing image (just in case)'
/opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD remoteimage -d

echo '******* Showing idrac remoteimage status'
/opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD remoteimage -s


echo "******* Connecting remote iso $ISO_URL to boot from"
/opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD remoteimage -c -l $ISO_URL

echo '******* Showing idrac remoteimage status'
/opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD remoteimage -s

if ! /opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD remoteimage -s | grep $ISO_URL; then
	usage 'ISO was not configured correctly'
fi

echo '******* Setting idrac to boot once from the attached iso'
/opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD set iDRAC.VirtualMedia.BootOnce 1
/opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD set iDRAC.ServerBoot.FirstBootDevice VCD-DVD

echo '******* Rebooting the server'
/opt/dell/srvadmin/bin/idracadm7 -r $HOST -u $USER -p $PASSWORD serveraction powercycle

echo '******* Done'

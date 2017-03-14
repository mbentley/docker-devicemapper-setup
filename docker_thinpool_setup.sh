#!/bin/bash

set -e

# check to see if you're running this as root
if [ "${UID}" -ne 0 ]
then
  echo "ERROR: you must run this script as root"
  exit 1
fi

# get block device name
BLOCK_DEVICE="${1:-}"

# verify a block device was provided
if [ -z "${BLOCK_DEVICE}" ]
then
  echo "ERROR: no block device specified"
  echo "Usage: ${0} /path/to/block/device"
  echo "Example: ${0} /dev/sdb"
  exit 1
fi

# give the user one last chance to quit
echo "Running this script will remove the following:"
echo "  * All data in /var/lib/docker"
echo "  * All data on ${BLOCK_DEVICE}"
echo ""

read -rp "Do you with to continue (y/n)? " choice
case "$choice" in
  y|Y|[yY][eE][sS])
    ;;
  *)
    echo "Aborting"
    exit 1
    ;;
esac

# stop docker
echo -e "\nEnsuring docker is stopped"
systemctl stop docker

# remove everything in /var/lib/docker
echo -e "\nRemoving all files in /var/lib/docker"
rm -rf /var/lib/docker/*

# check to see if we need to install lvm2
if ! pvdisplay > /dev/null 2>&1
then
  echo -e "\nInstalling lvm2"
  yum install -y lvm2
fi

# check to see if there is a physical device setup
if pvs "${BLOCK_DEVICE}" > /dev/null 2>&1
then
  echo -e "\nRemoving exiting LVM setup on ${BLOCK_DEVICE}"

  # get a list of volume groups
  VGS="$(pvdisplay -c "${BLOCK_DEVICE}"* 2> /dev/null | awk -F ':' '{print $2}')"
  for VG in ${VGS}
  do
    # get a list of logical volumes
    LVS="$(lvdisplay -c "${VG}" | awk -F ':' '{print $1}')"
    for LV in ${LVS}
    do
      # remove logical volume
      lvremove -f "${LV}"
    done

    # remove volume group
    vgremove -f "${VG}"
  done

  # check to see if there are multiple physical volumes (shouldn't be because this script isn't configured to properly handle this!)
  for PV in $(pvs --noheadings | awk '{print $1}')
  do
    # remove physical volume
    pvremove -f "${PV}"
  done
fi

# create a new physical volume
echo -e "\nCreating physical volume"
pvcreate -y "${BLOCK_DEVICE}" || (lsblk "${BLOCK_DEVICE}" || true; echo -e "\nERROR: Unable to create physical device; is the device already in use?"; exit 1)

# create a new volume group
echo -e "\nCreating volume group"
vgcreate docker "${BLOCK_DEVICE}"

# create a new thin pool for docker to use
echo -e "\nCreating thin pool"
lvcreate --wipesignatures y -n thinpool docker -l 95%VG
lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG
lvconvert -y --zero n -c 512K --thinpool docker/thinpool --poolmetadata docker/thinpoolmeta

# create an autoextend profile
echo -e "\nCreating auto extension profile"
cat << EOF > /etc/lvm/profile/docker-thinpool.profile
activation {
thin_pool_autoextend_threshold=80
thin_pool_autoextend_percent=20
}
EOF

# enable monitoring to ensure autoextend fires
echo -e "\nEnabling monitoring of the thin pool for auto extension"
lvchange --metadataprofile docker-thinpool docker/thinpool

# show user the monitoring is enabled
echo -e "\nVerifying monitoring was successfully enabled"
lvs -o+seg_monitor

# check to see if a daemon.json exists
if [ -f "/etc/docker/daemon.json" ]
then
  # create backup of daemon.json
  echo -e "\nExisting /etc/docker/daemon.json found; moving to daemon.json.bak"
  mv /etc/docker/daemon.json /etc/docker/daemon.json.bak
fi

# write devicemapper config to daemon.json
echo -e "\nWriting devicemapper configuration to /etc/docker/daemon.json"
cat << EOF > /etc/docker/daemon.json
{
  "storage-driver": "devicemapper",
   "storage-opts": [
     "dm.thinpooldev=/dev/mapper/docker-thinpool",
     "dm.use_deferred_removal=true",
     "dm.use_deferred_deletion=false"
   ]
}
EOF

# finished!
echo -e "\nThin pool setup complete.  Start the docker daemon to begin using the thin pool"

#!/bin/bash

if [ "${UID}" -ne 0 ]
then
  echo "This must be run as root"
  exit 1
fi

# shellcheck disable=SC1091 source=/dev/null
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/check_for_deferred_deletion.sh

echo "Kernel version: $(uname -r)"

# For RHEL/CentOS 7.4+, we need to enable this sysfs knob
KEY=fs.may_detach_mounts
M=$(sysctl -n "$KEY") \
	&& [ "$M" -eq "0" ] \
	&& {
		sysctl -q "$KEY=1"
		RESET_SYSCTL=true

		cat << EOF

WARNING: it seems you are using RHEL/CentOS 7.4+ kernel but the
$KEY sysfs setting is disabled (set to 0).

Setting $KEY = 1 for the duration of the test.

To enable this permanently, run the following:

	echo "$KEY=1" | sudo tee -a /etc/sysctl.d/90-docker.conf
	sudo sysctl -f /etc/sysctl.d/90-docker.conf

EOF
}

if platform_supports_deferred_deletion
then
  echo "Deferred deletion is supported"
else
  echo "Deferred deletion is not supported"
fi

if [ "$RESET_SYSCTL" = "true" ]
then
  sysctl -q "$KEY=0"
fi

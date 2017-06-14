#!/bin/bash

if [ "${UID}" -ne 0 ]
then
  echo "This must be run as root"
  exit 1
fi

# shellcheck disable=SC1091 source=/dev/null
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/check_for_deferred_deletion.sh

echo "Kernel version: $(uname -r)"

if platform_supports_deferred_deletion
then
  echo "Deferred deletion is supported"
else
  echo "Deferred deletion is not supported"
fi

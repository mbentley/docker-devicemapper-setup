#!/bin/bash

PIPE1=/run/dss-$$-fifo1
PIPE2=/run/dss-$$-fifo2
TEMPDIR=$(mktemp --tmpdir -d)

platform_supports_deferred_deletion() {
  set -x
  local deferred_deletion_supported=1
  trap cleanup_pipes EXIT
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  if [ ! -x "${DIR}/dss-child-read-write.sh" ];then
    return 1
  fi
  mkfifo $PIPE1
  mkfifo $PIPE2
  unshare -m "${DIR}"/dss-child-read-write.sh $PIPE1 $PIPE2 "$TEMPDIR" &
  read -r -t 10 n <>$PIPE1
  if [ "$n" != "start" ];then
    return 1
  fi
  rmdir "$TEMPDIR" > /dev/null 2>&1
  deferred_deletion_supported=$?
  echo "finish" > $PIPE2
  return $deferred_deletion_supported
  set +x
}

cleanup_pipes(){
  rm -f $PIPE1
  rm -f $PIPE2
  rmdir "$TEMPDIR" 2>/dev/null
}

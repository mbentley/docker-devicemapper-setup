docker-devicemapper-setup
=========================

Simple script to setup `devicemapper` on CentOS or RHEL for use with Docker.

  > **Warning**: This will destroy anything on the specified block device

### Usage
```
sudo ./docker_thinpool_setup.sh /path/to/block/device
```

### Example
```
sudo ./docker_thinpool_setup.sh /dev/sdb
```

### Enable deferred deletion (defaults to false)
```
sudo DEFERRED_DELETION=true ./docker_thinpool_setup.sh /dev/sdb
```

To programatically check for deferred deletion, see https://gist.github.com/mbentley/4dbdd400cf6d152c5d0741f2f6a0341e

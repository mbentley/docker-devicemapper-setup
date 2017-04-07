docker-devicemapper-setup
=========================

Simple script to setup `devicemapper` on CentOS, RHEL, or Oracle Linux for use with Docker.  These instructions are based of the official [direct-lvm configuration for production ](https://docs.docker.com/engine/userguide/storagedriver/device-mapper-driver/#configure-direct-lvm-mode-for-production) documentation.

  > **Warning**: This will destroy anything on the specified block device or partition!

### Usage
```
sudo ./docker_thinpool_setup.sh /path/to/block/device
```

### Example with a unpartition block device
```
sudo ./docker_thinpool_setup.sh /dev/sdb
```

### Example with a single partition on a block device
```
sudo ./docker_thinpool_setup.sh /dev/sdb3
```

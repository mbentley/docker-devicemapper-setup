docker-devicemapper-setup
=========================

Simple script to setup `devicemapper` on CentOS, RHEL, or Oracle Linux for use with Docker.

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

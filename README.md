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

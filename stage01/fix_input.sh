#!/bin/bash
SANPROVIDER="NetappProvider"
STORAGEMANAGER="SANManager"
echo "Setting $STORAGEMANAGER"
perl -i -p -e "s/EBS_STORAGE_MANAGER=.*\n/EBS_STORAGE_MANAGER=$STORAGEMANAGER\n/g" ../input/2b_tested.lst
echo "Setting $SANPROVIDER"
perl -i -p -e "s/SAN_PROVIDER=.*\n/SAN_PROVIDER=$SANPROVIDER\n/g" ../input/2b_tested.lst


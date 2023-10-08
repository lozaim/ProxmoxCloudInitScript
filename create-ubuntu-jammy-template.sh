#!/bin/bash

imageURL=https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
imageName="jammy-server-cloudimg-amd64.img"
diskName="jammy-server-cloudimg-amd64.qcow2"
volumeName="iso_ssd"
virtualMachineId="9000"
templateName="jammy-tpl"
tmp_cores="2"
tmp_memory="2048"
#rootPasswd="password"
#cpuTypeRequired="host"
if [ ! -f "$imageName" ] ; then
    wget -O $imageName $imageURL
fi

qm destroy $virtualMachineId
#virt-customize -a $imageName --root-password password:$rootPasswd
qm create $virtualMachineId --name $templateName --memory $tmp_memory --cores $tmp_cores --net0 virtio,bridge=vmbr1
cp $imageName $diskName
#qemu-img resize $diskName 20G
qm importdisk $virtualMachineId $imageName $volumeName --format qcow2
diskPath=$(eval "pvesm path $volumeName:$virtualMachineId/vm-$virtualMachineId-disk-0.qcow2")
qemu-img resize $diskPath 20G
qm set $virtualMachineId --scsihw virtio-scsi-single 
qm set $virtualMachineId --scsi0 $volumeName:$virtualMachineId/vm-$virtualMachineId-disk-0.qcow2
qm set $virtualMachineId --boot c --bootdisk scsi0
qm set $virtualMachineId --ide2 $volumeName:cloudinit
qm set $virtualMachineId --serial0 socket --vga serial0
qm set $virtualMachineId --ipconfig0 ip=dhcp
qm template $virtualMachineId

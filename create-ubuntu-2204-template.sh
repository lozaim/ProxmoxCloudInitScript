#!/bin/bash

imageURL=https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
imageName="ubuntu-22.04-server-cloudimg-amd64.img"
diskName="ubuntu-22.04-server-cloudimg-amd64.qcow2"
diskSize=20G
volumeName="iso_ssd"
templateId="9000"
templateName="2204-templ"
tmp_cores="1"
tmp_memory="2048"

# Check if image already exist
if [ ! -f "$imageName" ] ; then
    wget -O $imageName $imageURL
fi
# Destroy old template with same ID
qm destroy $templateId
echo ""
echo " VM Configuring. Please wait... "
echo ""
# Create VM with parametrs
qm create $templateId --name $templateName --memory $tmp_memory --cores $tmp_cores --agent=1  --net0 virtio,bridge=vmbr1,tag=20
# Rename image to disk
cp $imageName $diskName
# Move and format disk
qm importdisk $templateId $imageName $volumeName --format qcow2
# Find  disk location and resize
diskPath=$(eval "pvesm path $volumeName:$templateId/vm-$templateId-disk-0.qcow2")
qemu-img resize $diskPath $diskSize
# Attach device to VM
qm set $templateId --scsihw virtio-scsi-single 
qm set $templateId --scsi0 $volumeName:$templateId/vm-$templateId-disk-0.qcow2,ssd=1
qm set $templateId --boot c --bootdisk scsi0
qm set $templateId --ide0 $volumeName:cloudinit
qm set $templateId --serial0 socket --vga serial0
qm set $templateId --ipconfig0 ip=dhcp
# Create template from VM
qm template $templateId
echo ""
echo " Template from VM with id: $templateId and with name: $templateName had been created and configured"
echo ""

#!/bin/bash
#
# Scripfor for manually create VM from vm-template via CLI
#
templateId=9000

echo ""
echo " Proxmox Creation VM Tool"
echo ""
echo " Please follow the instructions"
echo ""
read -p " Please enter VM id: " virtualMachineId

echo $virtualMachineId

read -p " Please enter VM hostname: " vm_hostname

echo $vm_hostname
# Copy snippent to the new file, cnange hostname and apply snippet to template
cp /var/lib/vz/snippets/$templateId.yaml /var/lib/vz/snippets/$virtualMachineId-user-data.yaml
sed -i "s/ubuntu/$vm_hostname/" /var/lib/vz/snippets/$virtualMachineId-user-data.yaml
qm set $templateId --cicustom "user=local:snippets/$virtualMachineId-user-data.yaml"
# Create VM from template
pvesh create /nodes/prox2/qemu/$templateId/clone --newid $virtualMachineId --full --name=$vm_hostname
# Starting VM
qm start $virtualMachineId
echo ""
echo " VM Configuring. Please wait approx 120sec.. "
echo ""
# Timer
for (( i=120; i>0; i--)); do
  sleep 1 &
  printf "  $i \r"
  wait
done
# Check if VM still running
while [ "$output"  != "status: stopped" ]; do
  echo "VM still confuguring please wait"
  sleep 5
  output=$(eval "qm status $virtualMachineId")
done
# When VM stopped, unlink cloudinit disk
qm disk unlink $virtualMachineId --idlist ide0 --force
# Remove cloudinit string from VM config
sed -i '/cicustom/d' /etc/pve/qemu-server/$virtualMachineId.conf
sed -i '/sshkeys/d' /etc/pve/qemu-server/$virtualMachineId.conf
# Apply standart snipped to vm-template
qm set $templateId --cicustom "user=local:snippets/$templateId.yaml"
# Starting VM
qm start $virtualMachineId
# Check if VM still stopped
while [ "$output"  != "status: running" ]; do
  echo "VM starting. Please wait"
  sleep 5
  output=$(eval "qm status $virtualMachineId")
done

echo ""
echo " VM with id: $virtualMachineId and with hostname: $vm_hostname had been created and configured"
echo ""

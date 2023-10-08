#!/bin/bash
#
# Scripfor for manually create VM from vm-template via CLI
#
template_id=9000

echo ""
echo " Proxmox Creation VM Tool"
echo ""
echo " Please follow the instructions"
echo ""
read -p " Please enter VM id: " vm_id

echo $vm_id

read -p " Please enter VM hostname: " vm_hostname

echo $vm_hostname
# Copy snippent to the new file, cnange hostname and apply snippet to template
cp /var/lib/vz/snippets/$template_id.yaml /var/lib/vz/snippets/$vm_id-user-data.yaml
sed -i "s/ubuntu/$vm_hostname/" /var/lib/vz/snippets/$vm_id-user-data.yaml
qm set $template_id --cicustom "user=local:snippets/$vm_id-user-data.yaml"
# Create VM from template
pvesh create /nodes/prox2/qemu/template_id/clone --newid $vm_id --full --name=$vm_hostname
# Starting VM
qm start $vm_id
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
  output=$(eval "qm status $vm_id")
done
# When VM stopped, unlink cloudinit disk
qm disk unlink $vm_id --idlist ide0 --force
# Remove cloudinit string from VM config
sed -i '/cicustom/d' /etc/pve/qemu-server/$vm_id.conf
sed -i '/sshkeys/d' /etc/pve/qemu-server/$vm_id.conf
# Apply standart snipped to vm-template
qm set template_id --cicustom "user=local:snippets/template_id.yaml"
# Starting VM
qm start $vm_id
# Check if VM still stopped
while [ "$output"  != "status: running" ]; do
  echo "VM starting. Please wait"
  sleep 5
  output=$(eval "qm status $vm_id")
done

echo ""
echo " VM with id: $vm_id and with hostname: $vm_hostname had been created and configured"
echo ""

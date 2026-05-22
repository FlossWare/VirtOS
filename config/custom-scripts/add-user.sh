#!/bin/sh
# VirtOS - Add user for remote management

if [ "$#" -lt 1 ]; then
    echo "Usage: add-user.sh <username>"
    echo ""
    echo "Creates a user for remote virt-manager access"
    echo ""
    echo "Example:"
    echo "  add-user.sh vmadmin"
    exit 1
fi

USERNAME=$1

echo "Creating user: $USERNAME"

# Create user
adduser "$USERNAME"

# Set password
echo "Set password for $USERNAME:"
passwd "$USERNAME"

# Add to libvirt group
echo "Adding $USERNAME to libvirt group..."
adduser "$USERNAME" libvirt

# Add to wheel/sudo group (optional)
read -p "Add $USERNAME to sudo/admin group? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if grep -q "^wheel:" /etc/group; then
        adduser "$USERNAME" wheel
        echo "Added to wheel group"
    elif grep -q "^sudo:" /etc/group; then
        adduser "$USERNAME" sudo
        echo "Added to sudo group"
    fi
fi

echo ""
echo "User $USERNAME created successfully!"
echo ""
echo "Groups: $(groups $USERNAME)"
echo ""
echo "You can now connect remotely:"
echo "  virt-manager -c qemu+ssh://$USERNAME@virtos/system"
echo "  ssh $USERNAME@<virtos-ip>"
echo ""
echo "Set up SSH key for passwordless access:"
echo "  ssh-copy-id $USERNAME@<virtos-ip>"
echo ""

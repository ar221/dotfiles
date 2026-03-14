# Phone mount via sshfs (Termux on Z Fold 6)
set -l PHONE_USER "u0_a359"
set -l PHONE_IP "192.168.50.108"
set -l PHONE_PORT 8022
set -l PHONE_MOUNT "$HOME/mnt/phone"

alias mount-phone="mkdir -p $PHONE_MOUNT && sshfs -p $PHONE_PORT -o follow_symlinks $PHONE_USER@$PHONE_IP: $PHONE_MOUNT"
alias umount-phone="fusermount -u $PHONE_MOUNT"
alias mount-phone-storage="mkdir -p $PHONE_MOUNT-storage && sshfs -p $PHONE_PORT $PHONE_USER@$PHONE_IP:/storage/emulated/0 $PHONE_MOUNT-storage"
alias umount-phone-storage="fusermount -u $PHONE_MOUNT-storage"

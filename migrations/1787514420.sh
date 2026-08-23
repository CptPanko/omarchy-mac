echo "Migrating initial login to SDDM"

root_source=$(findmnt -no SOURCE / | sed "s/\.*\]//")

if [[ $(lsblk -no TYPE "$root_source") != "crypt" ]]; then
  sudo rm -f /etc/sddm.conf.d/autologin.conf
fi

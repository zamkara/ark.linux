#!/bin/bash
DISKS=""
while read -r line; do
    eval "$line"
    if [[ "$TYPE" == "disk" && "$RM" == "0" && "$TRAN" != "usb" && ! "$NAME" =~ ^(loop|zram|ram) ]]; then
        if [ -n "$MODEL" ]; then
            DISKS+="/dev/$NAME ($SIZE $MODEL)"$'\n'
        else
            DISKS+="/dev/$NAME ($SIZE)"$'\n'
        fi
    fi
done <<< "$(lsblk -d -n -P -o NAME,SIZE,MODEL,RM,TRAN,TYPE)"
echo "$DISKS"

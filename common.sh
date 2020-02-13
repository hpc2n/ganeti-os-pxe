#

# Copyright (C) 2007, 2008, 2009 Google Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.


log_error() {
  echo "$@" >&2
}

get_api5_arguments() {
  GETOPT_RESULT=$*
  # Note the quotes around `$TEMP': they are essential!
  eval set -- "$GETOPT_RESULT"
  while true; do
    case "$1" in
      -i|-n) instance=$2; shift 2;;

      -o) old_name=$2; shift 2;;

      -b) blockdev=$2; shift 2;;

      -s) swapdev=$2; shift 2;;

      --) shift; break;;

      *)  log_error "Internal error!" >&2; exit 1;;
    esac
  done
  if [ -z "$instance" -o -z "$blockdev" ]; then
    log_error "Missing OS API Argument (-i, -n, or -b)"
    exit 1
  fi
  if [ "$SCRIPT_NAME" != "export" -a -z "$swapdev"  ]; then
    log_error "Missing OS API Argument -s (swapdev)"
    exit 1
  fi
  if [ "$SCRIPT_NAME" = "rename" -a -z "$old_name"  ]; then
    log_error "Missing OS API Argument -o (old_name)"
    exit 1
  fi
}

get_api10_arguments() {
  if [ -z "$INSTANCE_NAME" -o -z "$HYPERVISOR" -o -z "$DISK_COUNT" ]; then
    log_error "Missing OS API Variable:"
    log_error "(INSTANCE_NAME HYPERVISOR or DISK_COUNT)"
    exit 1
  fi
  instance=$INSTANCE_NAME
  if [ $DISK_COUNT -lt 1 -o -z "$DISK_0_PATH" ]; then
    log_error "At least one disk is needed"
    exit 1
  fi
  if [ "$SCRIPT_NAME" = "export" ]; then
    if [ -z "$EXPORT_DEVICE" ]; then
      log_error "Missing OS API Variable EXPORT_DEVICE"
    fi
    blockdev=$EXPORT_DEVICE
  elif [ "$SCRIPT_NAME" = "import" ]; then
    if [ -z "$IMPORT_DEVICE" ]; then
       log_error "Missing OS API Variable IMPORT_DEVICE"
    fi
    blockdev=$IMPORT_DEVICE
  else
    blockdev=$DISK_0_PATH
  fi
  if [ "$SCRIPT_NAME" = "rename" -a -z "$OLD_INSTANCE_NAME" ]; then
    log_error "Missing OS API Variable OLD_INSTANCE_NAME"
  fi
  old_name=$OLD_INSTANCE_NAME
}

format_disk0() {
  # Create one big partition, and make it bootable
  # some versions of sfdisk need manual specification of 
  # head/sectors for devices such as drbd which don't 
  # report geometry
  sfdisk -H 255 -S 63 --quiet --Linux "$1" <<EOF
0,,L,*
EOF
}

map_disk0() {
  blockdev="$1"
  filesystem_dev_base=`kpartx -l -p- $blockdev | \
                       grep -m 1 -- "-1.*$blockdev" | \
                       awk '{print $1}'`
  if [ -z "$filesystem_dev_base" ]; then
    log_error "Cannot interpret kpartx output and get partition mapping"
    exit 1
  fi
  kpartx -a -p- $blockdev > /dev/null
  filesystem_dev="/dev/mapper/$filesystem_dev_base"
  if [ ! -b "$filesystem_dev" ]; then
    log_error "Can't find kpartx mapped partition: $filesystem_dev"
    exit 1
  fi
  echo "$filesystem_dev"
}

unmap_disk0() {
  kpartx -d -p- $1
}

cleanup() {
  if [ ${#CLEANUP[*]} -gt 0 ]; then
    LAST_ELEMENT=$((${#CLEANUP[*]}-1))
    REVERSE_INDEXES=$(seq ${LAST_ELEMENT} -1 0)
    for i in $REVERSE_INDEXES; do
      ${CLEANUP[$i]}
    done
  fi
}

DEFAULT_FILE="/etc/default/ganeti-instance-debootstrap"
if [ -f "$DEFAULT_FILE" ]; then
    . "$DEFAULT_FILE"
fi

# note: we don't set a default mirror since debian and ubuntu have
# different defaults, and it's better to use the default

# only if the user want to specify a mirror in the defaults file we
# will use it, this declaration is to make sure the variable is set
: ${MIRROR:=""}
: ${PROXY:=""}
: ${SUITE:="lenny"}
: ${ARCH:=""}
: ${EXTRA_PKGS:=""}
: ${CUSTOMIZE_DIR:="/etc/ganeti/instance-debootstrap.d"}
: ${GENERATE_CACHE:="yes"}
: ${CLEAN_CACHE:="14"} # number of days to keep a cache file
if [ -z "$OS_API_VERSION" -o "$OS_API_VERSION" = "5" ]; then
  DEFAULT_PARTITION_STYLE="none"
else
  DEFAULT_PARTITION_STYLE="msdos"
fi
: ${PARTITION_STYLE:=$DEFAULT_PARTITION_STYLE} # disk partition style

CACHE_DIR="/var/cache/ganeti-instance-debootstrap"

SCRIPT_NAME=$(basename $0)

if [ -f /sbin/blkid -a -x /sbin/blkid ]; then
  VOL_ID="/sbin/blkid -o value -s UUID"
  VOL_TYPE="/sbin/blkid -o value -s TYPE"
else
  for dir in /lib/udev /sbin; do
    if [ -f $dir/vol_id -a -x $dir/vol_id ]; then
      VOL_ID="$dir/vol_id -u"
      VOL_TYPE="$dir/vol_id -t"
    fi
  done
fi

if [ -z "$VOL_ID" ]; then
  log_error "vol_id or blkid not found, please install udev or util-linux"
  exit 1
fi

if [ -z "$OS_API_VERSION" -o "$OS_API_VERSION" = "5" ]; then
  OS_API_VERSION=5
  GETOPT_RESULT=`getopt -o o:n:i:b:s: -n '$0' -- "$@"`
  if [ $? != 0 ] ; then log_error "Terminating..."; exit 1 ; fi
  get_api5_arguments $GETOPT_RESULT
elif [ "$OS_API_VERSION" = "10" ]; then
  get_api10_arguments
else
  log_error "Unknown OS API VERSION $OS_API_VERSION"
  exit 1
fi

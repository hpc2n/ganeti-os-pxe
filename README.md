# ganeti-os-pxe

Ganeti-os for installing machines with PXE

http://docs.ganeti.org/ganeti/current/man/ganeti-os-interface.html

# How does it works?

The 'create' scripts overwrites the first part of the first disk of the vm with a etherboot pxe-enabled boot image.

After installing the machine the new OS will overwrite the boot image and boot normal after reboot.

# Install

Copy files into: /usr/lib/ganeti/os/pxe or /usr/local/lib/ganeti/os/pxe or whereever your "OS search path" (show with 'gnt-cluster info').

# eb-git-virtio-net.zhd

This file is a etherboot file downloaded from rom-o-matic.net at some point in time...

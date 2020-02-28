# ganeti-os-pxe

Ganeti-os definition for installing Ganeti/KVM virtual machines using PXE netboot.

http://docs.ganeti.org/ganeti/current/man/ganeti-os-interface.html

# How does it work?

The 'create' scripts overwrites the first part of the first disk of the vm with an Etherboot pxe-enabled boot image.

After installing the machine the new OS will overwrite the boot image and boot normal after reboot.

# Install

Copy files into: /usr/lib/ganeti/os/pxe or /usr/local/lib/ganeti/os/pxe or whereever your "OS search path" (show with 'gnt-cluster info').

Upon successful installation the command `gnt-os list` should list pxe as an alternative.

# DHCP server setup

This Etherboot PXE loader isn't fully PXE compliant in that it announces itself with the vendor class identifier Etherboot, not PXEClient as normal PXE clients.

If you are serving different responses based on the vendor class identifier, you'll need to cater for Etherboot as well and include a filename to boot with the DHCP reply.

Below is an example of how to do this with ISC DHCP server v4:

```
class "etherbootclients" {
    match if substring (option vendor-class-identifier, 0, 9) = "Etherboot";

    filename "pxelinux.0";
}
```

# eb-git-virtio-net.zhd

This file is an Etherboot file downloaded from rom-o-matic.net at some point in time...

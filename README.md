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

# Serial console note

While this isn't specific to this OS definition, Ganeti/KVM instances don't have the VGA-to-serial redirection that regular servers has, and thus requires serial console/output to be enabled in order to get any output in the `gnt-instance console` session.

This is done differently depending on bootloader, OS, etc.

For the pxelinux bootloader, serial console is enabled by adding the following to the pxelinux.cfg template:
```
serial 0 115200
```

For Linux operating systems you want an end result that ends up with `console=ttyS0,115200n8` or similar included in the kernel poot parameter list.


# eb-git-virtio-net.zhd

This file is an Etherboot file downloaded from rom-o-matic.net at some point in time...

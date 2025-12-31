---
title:                  "FreeBSD kernel development setup"
date:                   2025-12-14T20:00:00+01:00
type:                   posts
draft:                  false
showTableOfContents:    true
---
## Demonstration

<div id="demo"></div>
<link rel="stylesheet" type="text/css" href="/css/asciinema-player.css" />
<script src="/js/asciinema-player.min.js"></script>
<script type="text/javascript">
    AsciinemaPlayer.create('/asciinema/freebsd-kernel-development-setup.rec', document.getElementById('demo'));
</script>

## Introduction

I'm trying to learn more about how FreeBSD works.

There is a lot of hidden magic that kernel does which I would like to witness.
To help myself understand what is going on, I hope to build tools that will help me get useful information about what is happening within the kernel.

I'm a newbie to all of this and I'm trying to document everything I did.
Hopefully this blog can help someone to get started.

Please [contact me](mailto:blog@dautor.xyz):
- If you see something that can be done better.
- If you see something that is wrong.
- If you find a typo.

### Who is this blog post for?

1. Myself.
2. People who want to get into FreeBSD development but don't know where to start.
3. Experienced developers who can help me make this post better.

### Do I need a beefy computer for this?

Your computer doesn't need to be something super fast.
However, I'd recommend something that can compile FreeBSD source code decently fast so you don't have to wait a lot.

Compilation time depends on many factors, such as:
- your hardware
- what you're building
- if you've changed a commonly included header file

With 7800X3D, a full rebuild of 16-CURRENT kernel on 15.0-RELEASE takes about 2 minutes.
Building and installing the kernel when only one .c source file has changed takes about 2.5 seconds on the same machine.

## VM setup

We'll use 9P protocol to share the filesystem between VM and the host.
This makes installing software and running the VM super simple.

I don't know what the proper way to create this kind of VM would be, but these steps produce a usable VM for our purpose.
I would love to tell you to just download and unpack an archive (something like `FreeBSD-16.0-CURRENT-amd64-9P.txz`) and that you're done, but unfortunately only _raw_, _qcow2_, _vhd_ and _vmdk_ formats are distributed.

For now, download the latest VM and decompress it:

```sh
fetch https://download.freebsd.org/snapshots/VM-IMAGES/16.0-CURRENT/amd64/Latest/FreeBSD-16.0-CURRENT-amd64-ufs.raw.xz
xz --decompress FreeBSD-16.0-CURRENT-amd64-ufs.raw.xz
```

Start the VM:

```sh
sh /usr/share/examples/bhyve/vmrun.sh -P -v -m 1G -d FreeBSD-16.0-CURRENT-amd64-ufs.raw vm0
```

You will see the bootloader prompt on your terminal and can proceed with booting.
Once see it's waiting for a DHCP server and default route interface you can press `^C` to skip waiting.
Log in as _root_ and run the following commands to pack the whole filesystem into a single archive:
```sh
# inside the VM
cd /
tar cJf vm.txz *
```

Once it's done we need to move it out of the VM to the host.
We'll configure and start the ssh server inside the VM:
```sh
# inside the VM
passwd
# You will be asked to enter a new password.
# Just set it to "a". We'll only use it once and delete the VM after.
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
service sshd onestart
ifconfig vtnet0 10.255.255.1/24
```

Transfer the archive to the host:
```sh
# on the host
ifconfig tap0 10.255.255.2/24 # verify that tap0 is your newly-created interface
scp root@10.255.255.1:/vm.txz .
# enter your previously set password
```

After the transfer is done you can power off the VM and delete the `.raw` file:
```sh
poweroff
# ... after it exits:
rm FreeBSD-16.0-CURRENT-amd64-ufs.raw
```

Create a new directory (or a ZFS dataset) for your VM's filesystem and extract the archive:
```sh
mkdir vm0
tar -xf vm.txz -C vm0
rm -r vm0/dev/*
```

Tell the VM it will be running from 9P:
```sh
echo 'root / p9fs rw 0 0' > vm0/etc/fstab 
echo 'virtio_p9fs_load="YES"' > vm0/boot/loader.conf
echo 'vfs.root.mountfrom="p9fs:root"' >> vm0/boot/loader.conf
```

Load and run the VM:
```sh
bhyveload -m 1G -h vm0 vm0
bhyve -H -m 1G -A -G localhost:1234 -l com1,stdio -s 0,hostbridge -s 3,virtio-9p,root=vm0 -s 31,lpc vm0
# log in as root
# if you want to be automatically logged in as root, run this:
sed -i. 's|:np:nc:sp#0:|:al=root:np:nc:sp#0:|g' /etc/gettytab
# exit the VM
poweroff
```

Your VM is now all set up! :)

## Making changes to the kernel

### Getting FreeBSD-src

Clone the official FreeBSD source repository:
```sh
git clone --depth 1 ssh://anongit@git.FreeBSD.org/src.git .
mkdir obj
```

### Building the kernel

```sh
cd src
MAKEOBJDIRPREFIX=$(pwd)/../obj make -j $(sysctl -n hw.ncpu) -ss buildkernel
# this could take a while, depending on your hardware
```

### Installing the kernel

```sh
# from the src directory
MAKEOBJDIRPREFIX=$(pwd)/../obj make -j $(sysctl -n hw.ncpu) -ss DESTDIR=../vm0 installkernel
```

### Testing

Start the VM and check which kernel it is running:
```sh
# outside the src directory - where src, vm0 and obj directories are:
bhyveload -m 1G -h vm0 vm0 && bhyve -H -m 1G -A -G localhost:1234 -l com1,stdio -s 0,hostbridge -s 3,virtio-9p,root=vm0 -s 31,lpc vm0
# inside the VM once it's up:
uname -a
```

### Attaching a debugger

```sh
# from the src directory
kgdb -r localhost:1234 ../freebsd-obj/$(pwd)/amd64.amd64/sys/GENERIC/kernel
```

### Homework

Reading:
- read `man 7 build`.

Practice:
- Set a breakpoint on function 'strlen' and continue execution.
- Enter an empty command to the shell. (Press enter.)
- Check why 'strlen' is getting called.

Hint: `print (char const *)$rdi`

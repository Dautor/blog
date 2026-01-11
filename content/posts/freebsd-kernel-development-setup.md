---
title:                  "FreeBSD kernel development setup"
date:                   2025-12-14T20:00:00+01:00
type:                   posts
draft:                  false
tags:                   ["FreeBSD"]
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

Please [contact me](mailto:blog@dautor.xyz) if you have any feedback. :)

### Who is this blog post for?

1. Myself.
2. People who want to start with FreeBSD development but don't know how.

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

I will be using ZFS - so I will create a dataset to hold the VM:
```sh
zfs create -o mountpoint=/lab zroot/lab
zfs create zroot/lab/vm0
```

Fetch the necessary files:
```sh
cd /lab
fetch https://download.freebsd.org/snapshots/amd64/16.0-CURRENT/base.txz
fetch https://download.freebsd.org/snapshots/amd64/16.0-CURRENT/kernel.txz
```

Installing the VM:
```sh
tar -C vm0 base.txz
tar -C vm0 kernel.txz
```

Adding the necessary configuration:
```sh
cat <<EOF > vm0/boot/loader.conf
virtio_p9fs_load="YES"
vfs.root.mountfrom="p9fs:root"
EOF
echo 'hostname="freebsd"' > vm0/etc/rc.conf
echo 'root / p9fs rw 0 0' > vm0/etc/fstab
# if you want the VM to auto-login as root
sed -I'' 's|:np:nc:sp#0:|:al=root:np:nc:sp#0:|g' vm0/etc/gettytab
```

Create a snapshot with the configured VM:
```sh
zfs snap zroot/lab/vm0@base
```

Load and run the VM:
```sh
bhyveload -m 1G -h vm0 vm0 && bhyve -H -m 1G -A -G localhost:1234 -l com1,stdio -s 0,hostbridge -s 3,virtio-9p,root=vm0 -s 31,lpc vm0
```

Your VM is now all set up! :)

## Making changes to the kernel

### Getting FreeBSD-src

Clone the official FreeBSD source repository:
```sh
zfs create zroot/lab/src
zfs create zroot/lab/obj
git clone --depth 1 ssh://anongit@git.FreeBSD.org/src.git src
```

### Building the kernel

```sh
MAKEOBJDIRPREFIX=/lab/obj make -C src -j $(sysctl -n hw.ncpu) -ss buildkernel
# this could take a while depending on your hardware
```

### Installing the kernel

```sh
MAKEOBJDIRPREFIX=/lab/obj make -C src -j $(sysctl -n hw.ncpu) -ss DESTDIR=/lab/vm0 installkernel
```

### Testing

Start the VM and check which kernel it is running:
```sh
bhyveload -m 1G -h vm0 vm0 && bhyve -H -m 1G -A -G localhost:1234 -l com1,stdio -s 0,hostbridge -s 3,virtio-9p,root=vm0 -s 31,lpc vm0
# run this inside the VM once it's up:
uname -a
```

### Attach a debugger

```sh
# from the src directory
kgdb -r localhost:1234 /lab/obj/lab/src/amd64.amd64/sys/GENERIC/kernel
```

### Homework

Reading:
- read `man 7 build`.

Practice:
- Set a breakpoint on function 'strlen' and continue execution.
- Enter an empty command to the shell. (Press enter.)
- Check why 'strlen' is getting called.

Hint: `print (char const *)$rdi`

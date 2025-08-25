# xstrike

Keywords: kernel, linux, module, block device, regex, regex engine

Linux kernel module.

## TODO

- [ ] ioctl changing current regex pattern.
- [ ] open, release for cleanup.
- [ ] read, write:
   - [ ] Test what happens if data is given in multiple read or write calls `fpos`.
- [ ] regex engine:
   - [ ] character and string match.
   - [ ] ? and |.
   - [ ] +, *.

## Resources

- [Linux kernel source code](https://www.kernel.org/).
- [initramfs](https://en.wikipedia.org/wiki/Initial_ramdisk).
- [qemu](https://www.qemu.org/docs/master/index.html).
- [tty](https://en.wikipedia.org/wiki/Tty_(Unix)).
- [BusyBox 1.37](https://busybox.net/).
    - [GitHub Mirror](https://github.com/mirror/busybox).
- [Guide for running Linux/BusyBox in QEMU](https://gist.github.com/chrisdone/02e165a0004be33734ac2334f215380e).
- [Linux Kernel Documentation](https://docs.kernel.org/index.html):
   - [Building External Modules](https://docs.kernel.org/kbuild/modules.html#building-external-modules).
- [Device drivers](https://linux-kernel-labs.github.io/refs/heads/master/labs/device_drivers.html#).

## Notes

The Linux Kernel is compiled with a configuration file that defines what features of the kernel are build.
Since we only need the kernel for `qemu` to test during development, we can just take `tinyconfig`.

The following features need to be turned on:

- `initramfs` for user space.
- `printk` for logging.
- `tty`, `8250/16550 serial drivers` and `console` for console and serial, which is used by `qemu`.
- Running ELF files and files starting with `#!`.
- Turn on `Enable loadable module support` and `Module unloading` for loading and unloading modules (drivers).
- Turn on `sysfs` and `proc` for debug support.
- Create a script `init` and move it to `initramgs` directory. The scripts can just contain:
```bash
#!/bin/sh

exec /bin/sh
```
- Make the Makefile for modules, run with `make -C ./denv/linux-6.15.8/ M=$(pwd)`.
- Use `make` and copy the `.ko` file into `initramfs`.
- Load the module with `insmod [module_name]` and unload with `rmmod [module_name]`.
- Run `find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz`, to create a compressed version.
- The compiled kernel image can be found in `arch/x86/bzImage`.
- Start the system in `qemu` with:

```bash
qemu-system-x86_64 -kernel ./linux-6.15.8/arch/x86/boot/bzImage -nographic -append 'console=ttyS0 loglevel=7' -initrd initramfs.cpio.gz
```

- Turn on `Maintain a devtmpfs filesystem  to mount at /dev`, `Automount devtmpfs at /dev, after the kernel mounted on the rootfs`.


## Questions

- `initramfs`, `initrd`.
- What is a Linux image file.
- Why do we need `cpio`.
- The `init` executable or script?.
- Building modules docs.
- What does the `__init` macro do?
- sysfs and proc
- what is `__user`.
- what types should you use in the kernel.
- how is kmalloc implemented.
- what is the lifetime of memory passed through ioctl?
- What are pointers excatly i still get confused.
- What is sizeof() with a const string, whats the size etc.
- Add debug info to this notes

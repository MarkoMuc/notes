# xstrike

Keywords: kernel, linux, module, block device, regex, regex engine, regular expressions, image

Linux kernel module for applying regex patterns to input data.

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

Information on how to configure and setup the environment can be found [here.](https://github.com/MarkoMuc/xstrike/blob/master/denv/developer_environment.md).

The Linux Kernel is compiled with a configuration file that defines what features of the kernel are build.

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
- What are pointers exactly i still get confused.
- What is `sizeof()` with a `const string`, whats the size etc.

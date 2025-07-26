# xstrike

Keywords: kernel, linux, module, block device, regex, c

Linux kernel module.

## Resources

- [Linux kernel source code](https://www.kernel.org/).
- [initramfs](https://en.wikipedia.org/wiki/Initial_ramdisk).
- [qemu](https://www.qemu.org/docs/master/index.html).
- [tty](https://en.wikipedia.org/wiki/Tty_(Unix)).

## Notes

The Linux Kernel is compiled with a configuration file that defines what features of the kernel are build.
Since we only need the kernel for `qemu` to test during development, we can just take `tinyconfig`.

The following features need to be turned on:

- `initramfs` for user space.
- `printk` for logging.
- `tty` and `8250/16550 serial drivers` for console and serial, which is used by qemu.

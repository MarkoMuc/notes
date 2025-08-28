= Wayland Book

== Introduction

Wayland is the next generation display server for Unix-systems.

=== High-level design

Computers have multiple *input* and *output* devices, they are responsible for receiving information from you
and displaying information to you.

Output devices are generally displays. These resources are shared between all applications, and the role of
the *Wayland compositor* is to dispatch input events to the appropriate *Wayland client* and to display
their windows in their appropriate place on your outputs.

The process of bringing together all of your application windows for displaying on an output is called *composing*.

=== In practice

Multiple distinct software components are part of the graphics/display stack.
Some tools of the tools found part of the Linux desktop stack are:
- Mesa for rendering.
- Linux KMS/DRM.
- Buffer allocation with GBM.
- Userspace libdrm library, libinput, evdev, etc.

=== The hardware

Interfacing input and output devices is done by several components inside the operating system.
This can be interfaces for USB, PCI, etc. Hardware has little concept of what applications are
running on the system. The hardware only provides an interface with which it can be commanded to
perform work, and do what it is told, regardless of who tells it so. For this reason, only one component
is allowed to talk to hardware, this is the *kernel*.

=== The kernel

The job of the kernel is to provide an abstraction over the hardware, so that it can be safely accessed from the *userspace*.
The userspace is also where the Wayland compositor runs.

The graphics abstraction in the Linux kernel is called *DRM* or *direct rendering manager* #footnote[#link("https://en.wikipedia.org/wiki/Direct_Rendering_Manager")].
DRM tasks the GPU with work from the userspace.
The displays themselves are configured by a subsystem of DRM known as Linux *KMS* or *kernel mode setting*#footnote[#link("https://www.kernel.org/doc/html/v4.15/gpu/drm-kms.html")].

Input devices are abstracted through an interface called *evdev*#footnote[#link("https://en.wikipedia.org/wiki/Evdev")].

Most kernel interfaces are exposed to the userspace by the way of special files in `/dev`.
In the case of DRM, these files are in `/dev/dri`:
  - In the form of a primary node for privileged operations like modesetting.
  - In the form of render nodes for unprivileged operations like rendering or video decoding.

For evdev, the device nodes are in `/dev/input/event*`.

=== The userspace

Applications in the userspace are isolated from the hardware and must work with it via the device nodes provided by the kernel.

==== libdrm #footnote[#link("https://github.com/tobiasjakobi/libdrm")]

`libdrm` is the userspace portion of the DRM subsystem. It's a library providing an C API for interfacing with DRM.
`libdrm` is used by Wayland compositors to do modesetting and other DRM operatios. It is generally not used by the
Wayland clients directly.

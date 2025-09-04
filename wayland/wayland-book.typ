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

==== `libdrm` #footnote[#link("https://github.com/tobiasjakobi/libdrm")]

`libdrm` is the userspace portion of the DRM subsystem. It's a library providing an C API for interfacing with DRM.
`libdrm` is used by Wayland compositors to do mode setting and other DRM operations. It is generally not used by the
Wayland clients directly.

==== Mesa #footnote[#link("https://mesa3d.org/")]

Mesa is one of the core parts of the Linux graphics stack.
It provides an abstraction over `libdrm` known as *GBM* (Generic Buffer Management) library for
allocating buffers on the GPU. It also provides vendor-optimized implementations of OpenGL, etc.

==== `libinput` #footnote[#link("https://wayland.freedesktop.org/libinput/doc/latest/")]

`libinput` is the userspace abstraction library for evdev.
It's responsibility is to receive input events from the kernel, decoding them, and passing them to the Wayland compositor.
The Wayland compositor requires special permission to use the evdev files, forcing the Wayland clients to go through the
compositor to receive input events (for security reasons).

==== `(e)udev` #footnote[#link("https://en.wikipedia.org/wiki/Udev and https://github.com/eudev-project/eudev")]

Dealing with the appearance of new devices from the kernel, as well as configuring permissions for the resulting
device nodes in `/dev`, and sending word of the changes to the applications running on the system, is a responsibility
that falls onto the userspace. Most systems use `udev` or `eudev` for this purpose.
The Wayland compositor uses udev to interface, enumerate and notify about changes with input devices.

==== `xkbcommon` #footnote[#link("https://xkbcommon.org/")]

XKB is the original keyboard handling subsystem for Xorg server. Its now an independent keyboard library.
Libinput delivers keyboard events in the form of scan codes, which are keyboard dependent.
XKB translates the scan codes into generic key "symbols".
It also contains a state machine which knows how to process key combinations.

==== `pixman` #footnote[#link("https://www.pixman.org/")]

Library for efficient manipulation of pixel buffers.

==== `libwayland` #footnote[#link("https://wayland.freedesktop.org/")]

`libwayland` handles most of the low-level wire protocol.

=== The Wayland Package

The Wayland package consists of `libwayland-client`, `libwayland-server`, `wayland-scanner` and `wayland.xml`.
When installed they can be found in `/usr/lib & /usr/include`, `/usr/bin` and `/usr/share/wayland/`.
This package is the most popular implementation of Wayland.

- `wayland.xml`: Wayland protocols are defined by the XML files.
- `wayland-scanner`: Processes the XML files and generates code from them #footnote[Other scanners also exist, like `wayland-rs` and `waymonad-scanner`].
- `libwayland`: There are two libraries, one for the client side of the wire protocol and one for the server side.

== Protocol Design

The Wayland protocol consists of serveral layers of abstractions:

+ Basic wire protocol format, which is a stream of messages decodable with agreed upon interfaces.
+ Procedures for enumerating interfaces
+ Procedures for creating resources which conform to these interfaces
+ Procedures for exchanging messages about interfaces.

On top of this we also have some broader patters which are frequently used in Wayland protocol design.

=== Wire protocol basics

The wire protocol is a stream of 32-bit values, encoded with the host's byte order.
The protocol consists of the following primitive types:

- `int, uint`: 32-bit (un)signed integer.
- `fixed`: 24.8 bit signed fixed-point numbers.
- `object`: 32-bit object ID.
- `new_id`: 32-bit object ID which allocates that object when received.

The following other types are also used:

- `string`: It is prefixed with a 32-bit integer specifying its length in bytes,
            followed by the string contents and a `NUL` terminator, padded to 32 bits with undefined data.
- `array`: A blob of arbitrary data, prefix with a 32-bit integer of its length, then the contents, padded to 32 bits.
- `fd`: 0-bit value on the primary transport, but transfers a file descriptor to the other end using ancillary data
        in the Unix domain socket message (`msg_control`).
- `enum`: A single value or bitmap from an enumeration of known constants, encoded into a 32-bit integer.

==== Messages

The wire protocol is a stream of messages built with these primitives.
Every message is an event (server to client) or request (client to server) which acts upon an #emph("object").

Structure of the message

+ *header*: Two words
  - First word is the affected object ID.
  - Second word is two 16-bit values:
    - The upper 16 bits are the size of the message (including the header).
    - The lower 16 bits are the event or request opcode.
+ *arguments*: Based on a agreed upon in advance message signature.
  - The recipient looks up the object ID's interface and the event or request defined by its opcode to determine
    the signature and nature of the message.

To understand a message, the client and server have to establish the objects in the first place.
Object ID `1` is pre-allocated as the Wayland display `singleton`, and can be used to bootstrap other objects.

==== Object IDs

When a message comes in with a `new_id` argument, the sender allocates an object ID for it.
The interface used for this object is established through additional arguments, or agreed upon in advance for that request/event.
This object ID can be used in future messages as the first word of the header, or as an `object_id` argument.
The client allocates IDs in the range of `[1, 0xFEFFFFFF]`, and the server allocates IDs in the range of `[0xFF000000, OxFFFFFFFF]`.
IDs begin at the lower end of the range.

An object ID of `0` represents a null object; that is, a non-existent object or the explicit lack of an object.

==== Transports

The Unix domain socket is used for message transportation.
Unix sockets are used because of *file descriptor messages*.
This is the most practical transport capable of transferring file descriptors between processes,
which is necessary for large data transfers such as keymaps, pixel buffers, and mostly clipboard contents.
In theory other transports are also possible.

To find the Unix socket to connect to, most implementation do the same as libwayland:

+ If `WAYLAND_SOCKET` is set, interpret is as a file descriptor number on which the connection is already established,
  assuming that the parent process configured the connection for us. 
+ If `WAYLAND_DISPLAY` is set, concat with `XDG_RUNTIME_DIR` to form the path to the Unix socket.
+ Assure the socket name is `wayland-0` and concat with `XDG_RUNTIME_DIR` to form the path to the Unix socket.
+ Give up.

=== Interfaces, requests and event

The protocol works by issuing #emph("requests") and #emph("events") that act on #emph("objects").
Each object has an #emph("interface") which defines what requests and events are possible, and the #emph("signature") of each.
Let's consider an example interface: `wl_surface`.

==== Requests

A surface is a box of pixels that can be displayed on-screen.
It's one of the primitives, used for building application windows.
One of its #emph("requests"), send from the client to the server, is "damage",
which is used by the client to indicate that some part of the surface has changed and needs to be redrawn.

==== Events

Events are sent from the server to the client.
One of the events the server can send to the surface is "enter",
which it sends when the surface is being displayed on a specific output.

==== Interfaces

The interfaces which define the list of requests and events, the opcodes associated with each,
and the signatures with which you can decode the messages, are agreed upon in advance.

Interfaces are defined through the XML files (`wayland.xml`) mentioned beforehand.
Each interface is defined in this file, along with its requests and events, and their respective signatures.

During the XML file processing, we assign each request and event an opcode in the order that they appear,
numbered from `0` and incrementing independently.
Combined with the list of arguments, you can decode the request or event when it comes in over the wire,
and based on the documentation in the XML file you can decide how to program your software to behave accordingly.
This usually comes in the form of code generation.

=== Protocol design patterns

The following are some key concept used in the design of both the Wayland protocol and the protocol extensions.

==== Atomicity

Atomicity is the most important design pattern. Most interfaces allow you tu update them transactionally,
using several requests to build up a new representations of its state, then committing them all at once.

The interface includes separate requests for configuring each property of an object.
These are applied to a #emph("pending") state.
When the *commit* is sent, the pending state gets merged into the #emph("current") state.
This enables atomic updates within a single frame, resulting in no tearing or partially updates Windows.

==== Resource lifetimes

We wish to avoid sending events or requests to invalid objects.
Interfaces which define resources that have finite lifetimes will often include requests and events through
which the client or server can state their intention to no longer send requests or events for that object.
Only once both sides agree to this (asynchronously) do they destroy the resources they allocated for that object.

Wayland is a fully asynchronous protocol. Messages are guaranteed to arrive in the order they were sent, but only
with the respect to one sender. The client and server need to correctly handle the objects until a confirmation of
destruction in received.

== `libwayland` in depth

`libwayland` is the most popular Wayland implementation.
The library includes a few simple primitives and a pre-compiled version of `wayland.xml`, the core Wayland protocol.

=== `wayland-util` primitives

`wayland-util.h` defines a number of structures, utility functions and macros for Wayland applications.

Among these are:

  - Structures for *marshalling*#footnote[#link("https://en.wikipedia.org/wiki/Marshalling_(computer_science)")]
    and unmarshalling Wayland protocol messages in generated code.
  - A linked list `wl_list` implementation.
  - An array `wl_array` implementation.
  - Utilities for conversion between Wayland scalar types and C scalar types.
  - Debug logging.

=== `wayland-scanner`

`wayland-scanner` is packed with the Wayland package. It is used to generate C headers & glue code from the XML files.

Generally you run `wayland-scanner` at build time, then compile and link your application to the glue code.

=== Proxies and resources

An object is an entity known to the client and server that has some state, changes to which are negotiated over the wire.

On the client side, `libwayland` refers to these objects through the `wl_proxy` interface.
This is a proxy for the abstract object, and provides functions which are indirectly used by the client to marshall requests.
On the server side, objects are abstracted through `wl_resource`, which is similar to the proxy but also tracks which object
belongs to which client.

=== Interfaces and listeners

Interfaces and listeners are the highest abstraction in `libwayland`, primitives, proxies and listeners are just
low level implementations specific to each `interface` and `listener` generated  by `wayland-scanner`.

Both the client and server listen for messages using `wl_listener`.
The server-side code for interfaces and listeners is identical, but reversed.
When a message is received, it first looks up the object ID and its interface, then uses that to decode the message.
Then it looks for listeners on this object and invokes your functions with the arguments to the message.

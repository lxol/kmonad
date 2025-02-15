# KMonad

Welcome to the very first release of KMonad! Please bear with us, this is our
very first release, and our very first open source project of any real scale.
Let me start by immediately disappointing you if you are running Windows or Mac:
KMonad has been developed and tested solely on Linux and currently depends on
the linux `/dev/input` files and the `uinput` subsystem to interface with the
OS. Trying to get cross-platform support is high on my todo list, and any help
is greatly appreciated.

## What is KMonad?

KMonad is a keyboard remapping utility written to provide functionality that
aligns with that provided by the amazing [QMK
firmware](https://github.com/qmk/qmk_firmware/). The QMK firmware is compiled
and installed on programmable keyboards and allows your keyboards to transform
from comfortable clacky ("Wahaay!" for mechanical switches) to amazingly useful,
by introducing the ability to overlap various maps of keys, have different
functionality for the same key when held or tapped, or create buttons that can
be tapped multiple times to have different effects.

However, we can't always have our programmable keyboard with us, and I
personally don't like using it with my laptop, because it either becomes a
balancing act, or I have to sit at a table with my laptop uncomfortably far away
from me. Additionally, there are loads of people who do not have programmable
keyboards who might enjoy all the bells and whistles that QMK has to offer, and
so `KMonad` was born.

### What about that name, KMonad?

The name KMonad is a wink at my favorite window manager:
[XMonad](https://github.com/xmonad/xmonad), but where XMonad manages your
x-windows in its X-monad, we manage your Keys in our K-monad (actually, we call
it App, but who's checking).

### What can I do with KMonad?

Well, there are a variety of customizations you can make. For example, this
duplicates the functionality of another popular Linux utility: XCAPE, which
allows you to specify mod-buttons that also emit events when you simply tap
them. 

For example, look at that useless CapsLock key on your keyboard. It is in a
**great** position, but do we ever use it? Well, what if you could remap
CapsLock to a button that behaves like a Ctrl key? That's already quite nice.
What if it could also emit 'Esc' when you tap it? Yep: all of that is possible.

Do you write a lot of Haskell code and define your own operators? Do you want
your operators to look like this: =>=->->>? That's a lot to type. Why not just
define a macro that does it for you?

The same technique can be used to create macros that insert a variety of
accented or umlauted characters, depending on your OS. Why type `AltGr " e` when
you can put this macro in a layer on a button close to home row? (Note:
compose behavior depends on your OS, I don't think there is any 1 way to
implement this). 

Or more practically: do you really like the Dvorak layout, but do you also wish
you had very simple, left-handed access to the common Control z x c v shortcuts?
Have a look at [this dvorak
example](https://github.com/david-janssen/kmonad/blob/master/example/dvorak_sane_zxcv.kbd)
to see an easy solution.

For more ideas, check the `example` subdirectory, or the [syntax
guide](https://github.com/david-janssen/kmonad/blob/master/doc/syntax_guide.md)
for an overview of different button-types.

## Getting KMonad

KMonad is written in haskell (with a tiny bit of C). You can either compile it
yourself using the instructions mentioned below. Alternatively, the lovely
people over at https://github.com/nh2/static-haskell-nix have helped me figure
how to compile a static binary that should work basically on any standard 64-bit
linux system. Note that this is almost entirely untested, only on my own
computer and in a virtualbox running Ubuntu. You can download a binary for the
`0.1.0` release
[here](https://github.com/david-janssen/kmonad/releases/download/0.1.0/kmonad).

### Compiling
Probably the easiest way to compile KMonad is using `stack`. If you do not have `stack`
installed, check https://docs.haskellstack.org/en/stable/README/ for
instructions on installing it. After compilation, it can be removed again, since
`kmomad` does not need to be recompiled upon configuration.

After potentially installing `stack` and cloning this repo, you can build
`kmonad` by calling:
``` shell
stack build
```

Or call the following:
``` shell
stack haddock --no-haddock-deps
```
to build a KMonad binary and the haddock documentation. I have put some effort
into documenting the code if you want to have a look around. It is nowhere near
perfect, and I hope to do more in the future.

`stack` will tell you where it saved the compiled binary after which you can
copy it to somewhere on your path.

## Running
KMonad currently requires 1, and exactly 1 input argument: a path to a
configuration file that describes the keyboard layout to run. For a guide to
writing valid configuration files, [see the
syntax
guide](https://github.com/david-janssen/kmonad/blob/master/doc/syntax_guide.md)
or [some of the examples](https://github.com/david-janssen/kmonad/tree/master/example).

Once the compiled binary is on the PATH, running KMonad is as simple as:

``` shell
kmonad /path/to/config/file.kbd
```

Note that this interface is extremely provisional and subject to change.

Any kind of internal KMonad error that indicates that something has gone
seriously wrong with our representation of the computation will terminate KMonad
and display the error to stdout. It is however not uncommon for KMonad to have
to reacquire a uinput keyboard on resume from suspend. To that extent, any core
IO exception will cause KMonad to pause for a second and attempt a restart, ad
infinitum. This means its fine to unplug the mapped keyboard and plug it back
in, without crashing KMonad. 

### Uinput permissions
Currently, the only supported operating system is Linux. KMonad uses the
`uinput` subsystem to write events to the operating system. If you want to be
able to run KMonad without using sudo (highly recommended to avoid sudo wherever
possible), you will need to ensure that your user is part of the `uinput` group.
On most linux's this can be achieved by:

``` shell
sudo usermod -aG uinput username
```

Additionally, you might need to ensure that the `uinput` drivers are loaded
before starting KMonad, this can be achieved through:

``` shell
sudo modprobe uinput
```

This might have to be repeated whenever you restart your computer. There are
various techniques for getting the `uinput` subsystem to load automatically, but
I didn't manage to get any of them to work.

### Figuring out which event-file corresponds to your keyboard 
Sometimes you can find your keyboard listed under `/dev/input/by-id`. If so,
this is by far the best solution, since there is no guarantee that a keyboard
will be assigned the same numbered event-file. If this is not the case, however,
the easiest way to figure out which event-file corresponds to your keyboard is
probably to use the `evtest` linux utility. 

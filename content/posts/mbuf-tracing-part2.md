---
title:                  "mbuf tracing part 2"
date:                   2025-12-31T14:00:00+01:00
type:                   posts
draft:                  false
showTableOfContents:    true
---
## Adding a build time option
To add a build-time option, I added `MBUF_TRACE	opt_global.h` to `sys/conf/options`.
This will add it to `opt_global.h`, which is created dynamically during compilation and included automatically (using `-include` compiler option) to source files.
This option can then be checked in the source using `#if defined MBUF_TRACE` or `#ifdef MBUF_TRACE`.

## Adding a new source file

To `sys/conf/files` I added `kern/kern_mbuf_trace.c		optional mbuf_trace`.
`optional mbuf_trace` tells the build system to only build this file when `option mbuf_trace` is present.

## Wireshark

On FreeBSD, Wireshark is not compiled with Lua support.

I want to make traces into clickable links when they are file paths.
I want the link to open the file on that line in the editor.

I've lost 3 hours trying to get Wireshark to play along...
Documentation on how to create a dissectors in C as plugins is awful.

I got really frustrated with this and will leave it for now.
If you have experience with something like this and would like to help, please [contact me](mailto:blog@dautor.xyz).

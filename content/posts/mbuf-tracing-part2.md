---
title:                  "mbuf tracing part 2"
date:                   2025-12-31T14:00:00+01:00
type:                   posts
draft:                  false
showTableOfContents:    true
---
## Adding a build time option
To add a build-time option, I added `MBUF_TRACE	opt_global.h` to `sys/conf/options`.
This will add it to `opt_global.h`, which is created dynamically during compilation and included automatically (using `-include` compiler option).
The value of this option can then be checked by doing `#if defined MBUF_TRACE` or `#ifdef MBUF_TRACE`.

## Adding a new source file

To `sys/conf/files` I added `kern/kern_mbuf_trace.c		optional mbuf_trace`.
`optional mbuf_trace` tells the build system to only build this file when `option mbuf_trace` is enabled.

## Wireshark

On FreeBSD, Wireshark is not compiled with Lua support.

I wanted to make traces into clickable links when they resemble file paths.
I want these links to open the file:line in the editor so you can easily track in the source what the packet path was.

I've lost 3 hours trying to get Wireshark to play along and failed.
I'm convinced it is possible to create it with its module system but the documentation on how to create a dissectors in C that is a plugin is awful.
If you have experience with something like this and would like to contribute, please [contact me](mailto:blog@dautor.xyz).

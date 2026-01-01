---
title:                  "mbuf tracing part 3"
date:                   2026-01-01T20:00:00+01:00
type:                   posts
draft:                  false
tags:                   ["FreeBSD", "mbuf_trace"]
showTableOfContents:    true
---
![Result](/img/mbuf_trace_example1.png)

## Cleanup
I've spent some time today cleaning up formatting and testing usability.

When `mbuf_trace` option is disabled all `mtrace_*` and `mtrace` calls are #defined as empty.

I also stopped outputing the contents of mbufs implicitly. If the packet is "getting consumed" it won't make sense to dump its contents. More importantly, mbufs can be modified in-place at various places. For that reason it made sense to add explicit content tracing - `mtrace_data`.

## API

```C
mtrace_start(m)
mtrace_data(m)
mtrace_printf(m, f, ...)
mtrace_static_length(m, s, l)
mtrace_static(m, s)
mtrace_dynamic_length(m, s, l)
mtrace_dynamic(m, s)
mtrace(m, s)
mtrace_(m)
mtrace_enter(m)
mtrace_leave(m)
mtrace_func(m)
```
- `m` is a pointer to a `struct mbuf`.
- `s` is a pointer to an array of `char`.
- `mtrace_start` starts a trace. Tracing calls before `mtrace_start` are ignored.
This should allow us to add toggles for tracing on interfaces / firewall rules.
- `length` calls take explicit length argument `l`.
- Calling `static` variants should only be done with statically allocated strings - or at least with strings that will not be deallocated before the mbuf.
- Calling `dynamic` copies the string so the string can be deallocated.
- `mtrace` is an alias for `mtrace_static`.
- `mtrace_` captures `__FILE__:__LINE__`.
- `mtrace_enter`, `mtrace_leave` and `mtrace_func` capture `__FILE__:__LINE__: X__func__`, where `X` is +, -, or nothing, respectively.

## Capturing mbuf trace

`tcpdump` on interface `mbuf_trace`.

## TODO

Would it be cool if `ddb` was able to dump traces?

Currently tracing is always enabled or disabled.
I want to add toggles to:
- netgraph nodes
- network interfaces
- pf rules
- sockets (enabled at socket creation / after creation)
- processes (if start-start is enabled on a process, all mbufs that originate from it should have it enabled
- other ideas? [contact me](mailto:blog@dautor.xyz)


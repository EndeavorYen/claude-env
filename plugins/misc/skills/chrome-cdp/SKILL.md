---
name: chrome-cdp
description: Interact with local Chrome browser session (only on explicit user approval after being asked to inspect, debug, or interact with a page open in Chrome)
---

# Chrome CDP

Lightweight Chrome DevTools Protocol CLI. Connects directly via WebSocket — no Puppeteer, works with 100+ tabs, instant connection.

## Prerequisites

- Chrome (or Chromium, Brave, Edge, Vivaldi) with remote debugging enabled: open `chrome://inspect/#remote-debugging` and toggle the switch
- Node.js 22+ (uses built-in WebSocket)
- If your browser's `DevToolsActivePort` is in a non-standard location, set `CDP_PORT_FILE` to its full path

## Commands

All commands use `scripts/cdp.mjs`. The `<target>` is a **unique** targetId prefix from `list`; copy the full prefix shown in the `list` output (for example `6BE827FA`). The CLI rejects ambiguous prefixes.

### List open pages

```bash
scripts/cdp.mjs list
```

### Take a screenshot

```bash
scripts/cdp.mjs shot <target> [file]    # default: screenshot-<target>.png in runtime dir
```

Captures the **viewport only**. Scroll first with `eval` if you need content below the fold. Output includes the page's DPR and coordinate conversion hint (see **Coordinates** below).

### Accessibility tree snapshot

```bash
scripts/cdp.mjs snap <target>          # compact (default) — filters noise
scripts/cdp.mjs snap <target> --full   # complete AX tree with all nodes
```

### Evaluate JavaScript

```bash
scripts/cdp.mjs eval <target> <expr>
```

> **Watch out:** avoid index-based selection (`querySelectorAll(...)[i]`) across multiple `eval` calls when the DOM can change between them (e.g. after clicking Ignore, card indices shift). Collect all data in one `eval` or use stable selectors.

### Page status & console

The daemon buffers console output and exceptions in the background from the moment it starts. Use these commands to query the buffer.

```bash
scripts/cdp.mjs status  <target>                  # page state + new console/exception entries
scripts/cdp.mjs summary <target>                  # token-efficient page overview (~100 tokens)
scripts/cdp.mjs console <target> [--all|--errors] # console buffer (default: unread only)
```

> **Tip for agents:** Use `status` as your first command when debugging — it shows URL, title, and any console errors that have accumulated since the daemon started. Use `summary` for a quick page overview before deciding what to investigate.

### Other commands

```bash
scripts/cdp.mjs html    <target> [selector]   # full page or element HTML
scripts/cdp.mjs nav     <target> <url>         # navigate and wait for load
scripts/cdp.mjs net     <target>               # resource timing entries
scripts/cdp.mjs click   <target> <selector>    # click element by CSS selector
scripts/cdp.mjs clickxy <target> <x> <y>       # click at CSS pixel coords
scripts/cdp.mjs type    <target> <text>         # Input.insertText at current focus; works in cross-origin iframes unlike eval
scripts/cdp.mjs press   <target> <key>         # press key (Enter, Tab, Escape, Backspace, Space, Arrow*)
scripts/cdp.mjs scroll  <target> <dir|x,y> [px]  # scroll page (down/up/left/right; default 500px)
scripts/cdp.mjs loadall <target> <selector> [ms]  # click "load more" until gone (default 1500ms between clicks)
scripts/cdp.mjs hover   <target> <selector>          # hover element (triggers :hover, tooltips)
scripts/cdp.mjs waitfor <target> <selector> [ms]      # wait for element to appear (default 10s)
scripts/cdp.mjs fill    <target> <selector> <text>     # clear field + type text (form filling)
scripts/cdp.mjs select  <target> <selector> <value>    # select <select> option by value
scripts/cdp.mjs fullshot <target> [file]               # full-page screenshot (beyond viewport)
scripts/cdp.mjs styles  <target> <selector>            # computed styles (meaningful props only)
scripts/cdp.mjs cookies <target>                       # list cookies for current page
scripts/cdp.mjs evalraw <target> <method> [json]  # raw CDP command passthrough
scripts/cdp.mjs open    [url]                  # open new tab (each triggers Allow prompt)
scripts/cdp.mjs stop    [target]               # stop daemon(s)
```

## Coordinates

`shot` saves an image at native resolution: image pixels = CSS pixels × DPR. CDP Input events (`clickxy` etc.) take **CSS pixels**.

```
CSS px = screenshot image px / DPR
```

`shot` prints the DPR for the current page. Typical Retina (DPR=2): divide screenshot coords by 2.

## Tips

- Prefer `snap --compact` over `html` for page structure.
- Use `type` (not eval) to enter text in cross-origin iframes — `click`/`clickxy` to focus first, then `type`.
- Chrome shows an "Allow debugging" modal once per tab on first access. A background daemon keeps the session alive so subsequent commands need no further approval. Daemons auto-exit after 20 minutes of inactivity.
- `status` is the primary debug entry point — always start here. It shows buffered console errors without needing to "wait and capture".
- Console entries are buffered from the moment the daemon starts. Use `console --errors` to quickly find JS errors.

## Workflow Patterns

### Debugging a broken page
1. `status <target>` — check for console errors (buffered since daemon start)
2. `console <target> --errors` — detailed error messages + stack traces
3. `snap <target>` — inspect page structure
4. `styles <target> ".broken-element"` — check computed styles

### Form automation
1. `fill <target> "#email" "user@example.com"` — fill input
2. `select <target> "#country" "US"` — select dropdown
3. `press <target> Enter` — submit
4. `waitfor <target> ".success-message"` — wait for result

### Visual bug investigation
1. `summary <target>` — quick page overview
2. `fullshot <target>` — capture entire page
3. `styles <target> ".suspect"` — inspect layout properties
4. `eval <target> "document.querySelector('.suspect').getBoundingClientRect()"` — exact position

## Source & Changelog

**Upstream**: [pasky/chrome-cdp-skill](https://github.com/pasky/chrome-cdp-skill) (v1.0.1)

**Local modifications** (2026-03-16):
- **Background observation**: Daemon buffers console output and exceptions from startup; `status`, `console`, `summary` commands query the buffer
- **New commands**: `status` (primary debug entry point), `summary` (token-efficient overview), `console` (buffer query), `scroll`, `press` (keyboard events)
- **snap --full flag**: Allow full (non-compact) accessibility tree output
- **click upgrade**: Uses native CDP Input events instead of JS `.click()`
- **DPR fix**: Simplified detection to JS-only
- **Windows support**: `%LOCALAPPDATA%` browser paths, named pipes, POSIX guards
- **Edge filter**: `edge://` internal pages excluded from `list`
- **Automation commands**: `hover`, `waitfor`, `fill` (clear + type), `select` (dropdown)
- **Deep debug commands**: `fullshot` (full-page screenshot), `styles` (computed styles), `cookies`
- **Workflow patterns**: Added common debug/automation workflow documentation

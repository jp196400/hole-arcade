#!/usr/bin/env python3
"""Expose a queued IndexedDB flush on a Godot 4.3 web export.

Godot writes user:// into memory and only copies it to IndexedDB on quit.
GodotFS.sync() also drops a second call while one is in flight, so a save
during that window never reaches IndexedDB. This adds Module.syncPersistentFS,
which waits for the current flush and then syncs again.
"""
import sys
from pathlib import Path

ANCHOR = 'Module["initFS"]=GodotFS.init;'
HOOK = (
    'Module["syncPersistentFS"]=function(){'
    "function attempt(left){"
    "if(GodotFS._syncing&&left>0){return new Promise(function(r){setTimeout(function(){r(attempt(left-1));},40);});}"
    "return GodotFS.sync();}"
    "var prev=Module.__syncTail||Promise.resolve();"
    "var next=prev.then(function(){return attempt(25);},function(){return attempt(25);});"
    "Module.__syncTail=next.then(function(){},function(){});"
    "return next;};"
)


def main() -> None:
    path = Path(sys.argv[1])
    text = path.read_text()
    if "function attempt(left)" in text and "syncPersistentFS" in text:
        return
    simple = ANCHOR + 'Module["syncPersistentFS"]=function(){return GodotFS.sync()};'
    if simple in text:
        text = text.replace(simple, ANCHOR, 1)
    if ANCHOR not in text:
        raise SystemExit("IndexedDB sync hook point missing from index.js")
    path.write_text(text.replace(ANCHOR, ANCHOR + HOOK, 1))


if __name__ == "__main__":
    main()

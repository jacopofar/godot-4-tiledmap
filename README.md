# gotod-tiled-load
Dynamically loading Tiled maps in Godot


This is a Godot 4 project that shows how it's possible to load a Tiled map in JSON from an HTTP server.

# Features

* maps, tilesets and assets are loaded at runtime
* Tiled world files are used to split large maps into chunks to be loaded and unloaded as the player character moves
* layers
* animated tiles

this is probably not *good* GDScript code at all, but it works

See the reference "game" for a suitable Tiled map: https://github.com/jacopofar/reference_game

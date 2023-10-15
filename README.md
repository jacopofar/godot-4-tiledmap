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

## TO DO
- [x] Allow events to move around following a path
- [x] Add collisions to tiles
- [x] Let events collide with obstacles
- [x] Let events collide with the player
    - [ ] Let events react with collision with the player
- [ ] Global variable "storage" (singleton)
- [ ] Store globally the game details (e.g. tile size) to use them around
- [ ] Extend the events to do more:
    - [ ] Teleport
    - [ ] Change variable in storage
- [ ] allow remote control mode (the server can send keys, read variables state and take screenshots), useful for tests too
- [ ] schema validation outside godot? makes sense to be in the same repo still
- [ ] Allow events to have conditional states
- [ ] Handle event chunk migration (the event may move to a different chunk than the starting one, and must survive the chunk unload)

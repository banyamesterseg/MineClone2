# MineClone 2 Tools
This directory is for tools and scripts for MineClone 2.
Currently, the only tool is Texture Converter.

## Texture Converter (EXPERIMENTAL)
This is a Python script which converts a resource pack for Minecraft to
a texture pack for Minetest (and thus, MineClone 2).

**WARNING**: This script is currently incomplete, not all textures will be
converted. Some texture conversions are even buggy!
For a 100% complete texture pack, a bit of manual work will be required
afterwards.

Modes of operation:
- Can create a Minetest texture pack (default)
- Can update the MineClone 2 textures

Requirements:
- Know how to use the console
- Python 3
- ImageMagick

Usage:
- Make sure the file “`Conversion_Table.csv`” is in the same directory as the script
- In the console, run `./Texture_Converter.py -h` to learn the available options

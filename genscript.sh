#!/bin/bash

# This script generates useable resourcepacks in .zip format.
# Output located in ./generated

# Pack version
PACKVER=v"2.0 B2"

# Minecraft version ranges for each pack format
MCVER=(1.6.1-1.7.10 1.8-1.8.9 1.9–1.10.2 1.11–1.12.2 1.13–1.14.4 1.15–1.16.1 1.16.2–1.16.5 1.17–1.17.1 1.18–1.18.2 1.19–1.19.2 0 0 1.19.3 1.19.4 0 1.20–1.20.1 0 0 1.20.2 0 1.21)

# DPI range for GUI sizes
DPI=(0 24 48 72 96 120 144 168 192)

# Exit if running under root
[ "$EUID" = 0 ] && {

    echo
    echo ":: Please run without root privileges."
    echo
    exit 1
}

# Exit if running in wrong directory
[ -e "./dev/genscript_enable" ] || {

    echo
    echo ":: Please run inside source folder."
    echo
    exit 1
}

# Check deps
hash inkscape 2>/dev/null || {

    echo "Inkscape is not installed."
    EXIT=1
}
hash 7z 2>/dev/null || {

    echo "7z (7-Zip, p7zip) is not installed."
    EXIT=1
}
hash sed 2>/dev/null || {

    echo "sed is not installed."
    EXIT=1
}
hash optipng 2>/dev/null || {

    echo "optipng is not installed."
    EXIT=1
}
[ "$EXIT" = "1" ] && {

    echo
    echo ":: One or more dependencies are missing. Exiting."
    echo
    exit 1
}

# Check if generated packs already exist
if [ -d "./generated" ]; then

    while [ "$INPUT" != "y" ]; do

        echo
        echo ":: Generated packs already exist. Regenerate? [y/n]"
        read -s -n 1 INPUT
        [ "$INPUT" = "n" ] && exit 1
        [ "$INPUT" = "y" ] && \rm -r ./generated
    done
fi

# Enable globstar during script
shopt -s globstar

# Generate useable PNGs
echo ":: Starting generation (this may take a while!)"
mkdir ./temp
for SCALE in 2 3 4 5 6 7 8; do

    echo "Generating for scale $SCALE..."
    cp -r ./src ./temp/$SCALE
    for SVG in ./temp/$SCALE/**/*.svg; do
        inkscape "$SVG" -d ${DPI[$SCALE]} --export-filename "${SVG%svg}png"
    done
done

# Remove temporary SVGs
for SVG in ./temp/**/*.svg; do

    rm $SVG
done

# Compress PNGs
echo "Compressing images..."
for PNG in ./temp/**/*.png; do

    optipng $PNG
done

# Sort and compress files
echo "Zipping packs..."
mkdir ./generated
for SCALE in 2 3 4 5 6 7 8; do

    for FRMT in 20 18 15 13 12 9 8 7 6 5 4 3 2 1 0; do

        [ $SCALE = 2 ] && mkdir ./generated/$FRMT
        sed -i -e "s/-FRMT/$FRMT/g" ./temp/$SCALE/pack.mcmeta
        sed -i -e "s/-SCALE/$SCALE/g" ./temp/$SCALE/pack.mcmeta
        [ "$FRMT" = 13 ] && \cp -r ./temp/$SCALE/1.19.3-1.19.4/minecraft ./temp/$SCALE/assets
        [ "$FRMT" = 9 ] && \cp -r ./temp/$SCALE/1.9-1.19.2/minecraft ./temp/$SCALE/assets
        [ "$FRMT" = 1 ] && \cp -r ./temp/$SCALE/1.8-1.8.9/minecraft ./temp/$SCALE/assets
        [ "$FRMT" = 0 ] && {
            sed -i -e "s/: 0/: 1/g" ./temp/$SCALE/pack.mcmeta
            \cp -r ./temp/$SCALE/1.6.1-1.7.10/minecraft ./temp/$SCALE/assets
        }
        7z a "./generated/$FRMT/Dracula $PACKVER GUI Scale $SCALE MC ${MCVER[$FRMT]}.zip" ./temp/$SCALE/assets ./temp/$SCALE/LICENSE.md ./temp/$SCALE/pack.mcmeta ./temp/$SCALE/pack.png
        sed -i -e "s/: $FRMT/: -FRMT/g" ./temp/$SCALE/pack.mcmeta
    done
done

# Clean up and send finished message
\rm -r ./temp
echo
echo ":: Done. Output availible in ./generated"
echo

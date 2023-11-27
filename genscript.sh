#!/bin/bash

# This script generates useable resourcepacks in .zip format.
# Output located in ./generated

# Pack version
PACKVER="Dev"

# Pack formats to generate
FORMATS=(20 18 15 13 12 9 8 7 6 5 4 3 2 1 0)

# Minecraft version ranges for each pack format
MCVER=(1.6.1-1.7.10 1.8-1.8.9 1.9–1.10.2 1.11–1.12.2 1.13–1.14.4 1.15–1.16.1 1.16.2–1.16.5 1.17–1.17.1 1.18–1.18.2 1.19–1.19.2 0 0 1.19.3 1.19.4 0 1.20–1.20.1 0 0 1.20.2 0 1.21)

# DPI range for GUI sizes
DPI=(0 24 48 72 96 120 144 168 192)

# GUI Scales to generate
SCALES=(2 3 4 5 6 7 8)

# Exit if running under root
[ "${EUID}" = 0 ] && {

    echo
    echo ":: Please run without root privileges."
    echo
    exit 1
}

# Exit if running in wrong directory
[ -e "./dev/script_enabler" ] || {

    echo
    echo ":: Please run inside source folder."
    echo
    exit 1
}

# Check deps
MISSING=0
hash inkscape 2>/dev/null || {

    echo "Inkscape is not installed."
    MISSING=$((${MISSING}+1))
}
hash 7z 2>/dev/null || {

    echo "7z (7-Zip, p7zip) is not installed."
    MISSING=$((${MISSING}+1))
}
hash mogrify 2>/dev/null || {

    echo "imagemagick is not installed."
    MISSING=$((${MISSING}+1))
}
hash optipng 2>/dev/null || {

    echo "optipng is not installed."
    MISSING=$((${MISSING}+1))
}

# Exit if dependencies aren't met
[ "${MISSING}" -gt "0" ] && {

    echo
    echo ":: ${MISSING} dependencies are missing. Exiting."
    echo
    exit 1
}

# Check if ./temp directory exists
if [ -d ./temp ]; then

    while [ "$INPUT" != "y" ]; do

        echo
        echo ":: ./temp directory already exists (script error?). Remove? [y/n]"
        read -s -n 1 INPUT
        [ "$INPUT" = "n" ] && exit 1
        [ "$INPUT" = "y" ] && \rm -r ./temp
    done
fi

# Check if generated packs already exist
if [ -d ./generated ]; then

    while [ "$INPUT" != "y" ]; do

        echo
        echo ":: Generated packs already exist. Regenerate? [y/n]"
        read -s -n 1 INPUT
        [ "$INPUT" = "n" ] && exit 1
        [ "$INPUT" = "y" ] && \rm -r ./generated
    done
fi

echo ":: Starting generation (this may take a while!)"

# Enable globstar during script
shopt -s globstar

# Generate useable PNGs
mkdir ./temp
for SCALE in ${SCALES[@]}; do

    echo "Generating images for scale ${SCALE}..."
    rsync -a --exclude="*.svg" ./src/ ./temp/${SCALE}
    for SVG in ./src/**/*.svg; do

        PNG=$(sed "s~src/~temp/$SCALE/~" <<< ${SVG} | sed -e "s~.svg~.png~")
        echo "file-open:${SVG}; export-filename:${PNG}; export-dpi:${DPI[$SCALE]}; export-do" >> ./temp/${SCALE}/inkscape.txt
    done
    echo "quit" >> ./temp/${SCALE}/inkscape.txt
    inkscape --shell < ./temp/${SCALE}/inkscape.txt &>/dev/null
done

# Remove almost fully transparent pixels that don't play nice with Minecraft's texture rendering.
for SCALE in ${SCALES[@]}; do

    echo "Removing redundant pixels for scale $SCALE..."
    for PNG in ./temp/$SCALE/**/*.png; do

        mogrify -fuzz 7% -channel RGBA -fill "#ffffff" -transparent "#88888800" ${PNG}
    done
done

# Compress generated PNG files
for SCALE in ${SCALES[@]}; do

    echo "Optimizing images for scale $SCALE..."
    for PNG in ./temp/$SCALE/**/*.png; do

        optipng -q ${PNG}
    done
done


# Sort and compress files
echo "Zipping packs..."
mkdir ./generated
for SCALE in ${SCALES[@]}; do

    sed -i "s/SCALE/${SCALE}/g" ./temp/${SCALE}/pack.mcmeta
    for FORMAT in ${FORMATS[@]}; do

        [ ${SCALE} = 2 ] && mkdir ./generated/${FORMAT}
        sed -i "s/FORMAT/${FORMAT}/g" ./temp/${SCALE}/pack.mcmeta
        if [ -d ./temp/${SCALE}/${FORMAT} ]; then

            \cp -r ./temp/${SCALE}/${FORMAT}/* ./temp/${SCALE}/assets
            [ "${FORMAT}" = 0 ] && sed -i "s/: 0/: 1/g" ./temp/${SCALE}/pack.mcmeta
        fi
        7z a "./generated/${FORMAT}/Dracula ${PACKVER} GUI Scale ${SCALE} MC ${MCVER[$FORMAT]}.zip" ./temp/${SCALE}/assets ./temp/${SCALE}/LICENSE.md ./temp/${SCALE}/pack.mcmeta ./temp/${SCALE}/pack.png &>/dev/null
        sed -i "s/: ${FORMAT}/: FORMAT/g" ./temp/${SCALE}/pack.mcmeta
    done
done

# Clean up and send finished message
\rm -r ./temp
echo
echo ":: Done. Output availible in ./generated"
echo

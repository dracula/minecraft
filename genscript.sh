#!/bin/bash

# This script generates useable resourcepacks in .zip format.
# Output located in ./generated

# Exit if running under root
if [ "$EUID" = 0 ]
    then
    echo
    echo ":: Please run without root privileges"
    echo
    exit 1
fi

# Check deps
hash inkscape 2>/dev/null || {
    echo >&2 "Inkscape is not installed."
    EXIT=1
}
hash 7z 2>/dev/null || {
    echo >&2 "7z (7-Zip, p7zip) is not installed."
    EXIT=1
}
hash sed 2>/dev/null || {
    echo >&2 "sed is not installed."
    EXIT=1
}
[ "$EXIT" = "1" ] && {
    echo
    echo "One or more dependencies are missing. Aborting."
    echo
    exit 1
}

# Check if generated packs already exist
[ -d "./generated" ] && {
    while [ "$INPUT" != "y" ]
    do
        echo
        echo "Generated packs already exist. Regenerate? (y/n)"
        read -s -n 1 INPUT
        [ "$INPUT" = "n" ] && exit 1
        [ "$INPUT" = "y" ] && \rm -r ./generated
    done

}

# Pack version
PACKVER=v2.0

# MC versions based on pack format
MCVER=(1.6.1-1.7.10 1.8-1.8.9 1.9–1.10.2 1.11–1.12.2 1.13–1.14.4 1.15–1.16.1 1.16.2–1.16.5 1.17–1.17.1 1.18–1.18.2 1.19–1.19.2 0 0 1.19.3 1.19.4 0 1.20–1.20.1 0 0 1.20.2)

# GUI scale DPIs
GUI=(0 24 48 72 96 120 144 168 192)

# Initial setup
mkdir ./tmp
for SCALE in 2 3 4 5 6 7 8
do
    echo "Generating for scale $SCALE..."
    cp -r ./src ./tmp/$SCALE
    for file in ./tmp/$SCALE/*/*/*/*/*.svg
    do
        inkscape "$file" -d ${GUI[$SCALE]} --export-filename "${file%svg}png"
    done
    for file in ./tmp/$SCALE/*/*/*/*/*/*.svg
    do
        inkscape "$file" -d ${GUI[$SCALE]} --export-filename "${file%svg}png"
    done
    for file in ./tmp/$SCALE/*/*/*/*/*/*/*.svg
    do
        inkscape "$file" -d ${GUI[$SCALE]} --export-filename "${file%svg}png"
    done
    for file in ./tmp/$SCALE/*/*/*/*/*/*/*/*.svg
    do
        inkscape "$file" -d ${GUI[$SCALE]} --export-filename "${file%svg}png"
    done
done

# Delete temp SVGs
rm ./tmp/*/*/*/*/*/*.svg
rm ./tmp/*/*/*/*/*/*/*.svg
rm ./tmp/*/*/*/*/*/*/*/*.svg
rm ./tmp/*/*/*/*/*/*/*/*/*.svg

# Pack Zipping
echo "Zipping packs..."
mkdir ./generated
for SCALE in 2 3 4 5 6 7 8
do
    for FRMT in 18 15 13 12 9 8 7 6 5 4 3 2 1 0
    do
        [ $SCALE = 2 ] && mkdir ./generated/$FRMT
        sed -i -e "s/-FRMT/$FRMT/g" ./tmp/$SCALE/pack.mcmeta
        sed -i -e "s/-SCALE/$SCALE/g" ./tmp/$SCALE/pack.mcmeta
        [ "$FRMT" = 13 ] && \cp -r ./tmp/$SCALE/1.19.3-1.19.4/minecraft ./tmp/$SCALE/assets
        [ "$FRMT" = 9 ] && \cp -r ./tmp/$SCALE/1.9-1.19.2/minecraft ./tmp/$SCALE/assets
        [ "$FRMT" = 1 ] && \cp -r ./tmp/$SCALE/1.8-1.8.9/minecraft ./tmp/$SCALE/assets
        [ "$FRMT" = 0 ] && {
            sed -i -e "s/: 0/: 1/g" ./tmp/$SCALE/pack.mcmeta
            \cp -r ./tmp/$SCALE/1.6.1-1.7.10/minecraft ./tmp/$SCALE/assets
        }
        cd ./generated/$FRMT
        7z a "Dracula $PACKVER GUI Scale $SCALE MC ${MCVER[$FRMT]}.zip" \
            ../../tmp/$SCALE/assets ../../tmp/$SCALE/LICENSE ../../tmp/$SCALE/pack.mcmeta ../../tmp/$SCALE/pack.png \
            > /dev/null 2>&1
        cd ../..
        sed -i -e "s/: $FRMT/: -FRMT/g" ./tmp/$SCALE/pack.mcmeta
    done
done

# Clean up and send finished message
\rm -r ./tmp
echo
echo "Done. Output availible in ./generated"
echo

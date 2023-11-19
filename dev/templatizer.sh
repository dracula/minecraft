#!bin/bash

# Exit if running under root
[ "$EUID" = 0 ] && {

    echo
    echo ":: Please run without root privileges."
    echo
    exit 1
}

# Exit if running in wrong directory
[ -e "./script_enabler" ] || {

    echo
    echo ":: Please run inside ./dev folder."
    echo
    exit 1
}

# Check deps
hash inkscape 2>/dev/null || {

    echo "Inkscape is not installed."
    EXIT=1
}
hash sed 2>/dev/null || {

    echo "sed is not installed."
    EXIT=1
}
[ "$EXIT" = "1" ] && {

    echo
    echo ":: One or more dependencies are missing. Exiting."
    echo
    exit 1
}

# Get modid to generate in from user
VALID=0
while [ "$VALID" = "0" ]; do

    echo
    echo ":: Input a valid modid to generate templates in (the folders inside /src/assets)"
    read MODID
    [ -d "../src/assets/$MODID/" ] && VALID=1
done

# Enable globstar during script
shopt -s globstar

# Primary loop
for FILE in ../src/assets/$MODID/**/*.png; do

    inkscape -p $FILE -o temp.svg
    cp ./base.svg ${FILE%png}svg
    for LINE in 37 36 35 34 33 32 31; do

        sed -n ${LINE}p temp.svg | sed -i '38r /dev/stdin' ${FILE%png}svg
        # Yes, this is a very lazy solution
    done
    WIDTH=$(inkscape -W -p temp.svg)
    HEIGHT=$(inkscape -H -p temp.svg)
    sed -i s~width=\"$WIDTH\"~width=\"$((WIDTH*4))\"~ ${FILE%png}svg
    sed -i s~width=\"1024\"~width=\"$((WIDTH*4))\"~ ${FILE%png}svg
    sed -i s~height=\"$HEIGHT\"~height=\"$(($HEIGHT*4))\"~ ${FILE%png}svg
    sed -i s~height=\"1024\"~height=\"$(($HEIGHT*4))\"~ ${FILE%png}svg
    rm temp.svg
done

echo
echo ":: Finished generating templates for $MODID."
echo

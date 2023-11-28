#!bin/bash

# Generates

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
[ "$EXIT" = "1" ] && {

    echo
    echo ":: One or more dependencies are missing. Exiting."
    echo
    exit 1
}

# Check if there're files in ./templatizer/input
[ -e ./templatizer/input/* ] || {

    echo
    echo ":: There's nothing inside ./templetizer/input!"
    echo
    exit 1
}

# Enable globstar during script
shopt -s globstar

echo "Copying all non-PNG files..."
rsync -a --exclude="*.png" ./templatizer/input/ ./templatizer/output

echo "Creating templates..."
for INPUT in ./templatizer/input/**/*.png; do

    OUTPUT=$(sed -e 's~templatizer/input~templatizer/output~;s~.png~.svg~' <<< ${INPUT})    # Set OUTPUT as image file corresponding to input
    inkscape -p $INPUT -o ./templatizer/temp.svg    # Create temporary SVG to get image code from
    cp ./base.svg ${OUTPUT} # Create a copy of base.svg at output path
    for LINE in 37 36 35 34 33 32 31; do # Loop for lines in temp svg that has the image code and add it to OUTPUT. Yes, this is a very lazy solution

        sed -n ${LINE}p ./templatizer/temp.svg | sed -i '38r /dev/stdin' ${OUTPUT}
    done
    WIDTH=$(inkscape -W -p ./templatizer/temp.svg)  # Set WIDTH as width of temp.svg using inkscape
    HEIGHT=$(inkscape -H -p ./templatizer/temp.svg) # Same as width but for height
    # All the bellow commands set the correct width and height in output file. Multiple passes are needed since there is the static SVG size and then the size of copied image itself.
    sed -i s~width=\"$WIDTH\"~width=\"$((WIDTH*4))\"~ ${OUTPUT}
    sed -i s~width=\"1024\"~width=\"$((WIDTH*4))\"~ ${OUTPUT}
    sed -i s~height=\"$HEIGHT\"~height=\"$(($HEIGHT*4))\"~ ${OUTPUT}
    sed -i s~height=\"1024\"~height=\"$(($HEIGHT*4))\"~ ${OUTPUT}
    rm ./templatizer/temp.svg
done

echo
echo ":: Finished generating templates."
echo

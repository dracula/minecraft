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

# Enable globstar during script
shopt -s globstar

for FILE in ../src/**/*.svg; do

    sed -i "s/export-.dpi=".*"/export-.dpi="96"/" $FILE
    sed -i "s/export-filename=".*"/export-filename="$FILE"/" $FILE
    sed -i "s/showgrid=".*"/showgrid="true"/" $FILE
    sed -i "s/emspacing=".*"/emspacing="4"/" $FILE
    sed -i "snapvisiblegridlinesonly=".*"/snapvisiblegridlinesonly="true"/" $FILE
    sed -i "s/id="grid.*"/id="Main Grid"/" $FILE
done

echo
echo ":: Scan finished."
echo

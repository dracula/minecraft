#!bin/bash

# Exit if running under root
[ "$EUID" = 0 ] && {

    echo
    echo ":: Please run without root privileges."
    echo
    exit 1
}

# Exit if running in wrong directory
[ -e ./script_enabler ] || {

    echo
    echo ":: Please run inside ./dev folder."
    echo
    exit 1
}

# Confirm whether or not to run script
INPUT=0
while [ "$INPUT" != "y" ]; do

    echo
    echo ":: Are you sure you want to overwrite existing language files? [y/n]"
    read -s -n 1 INPUT
    [ "${INPUT}" = "n" ] && exit 1
    [ "${INPUT}" = "y" ] && \rm ../src/*/*/lang/*
done

for VER in ./lang/*/; do    # Loops through any directories present in ./dev/lang containing reference files to account for removed lang keys

    for MODPATH in ${VER}/*/; do    # Loops through subdirs in previous parent loop to separate mods

        MODID=$(basename ${MODPATH})
        for LANGPATH in ${MODPATH}/*.json; do   # Loops through reference language files

            LANGFILE=$(basename $LANGPATH)
            echo "Pass ${VER} ${LANGFILE}..."   # Status message
            cp -n ./lang/${MODID}.json ../src/assets/${MODID}/lang/${LANGFILE} 2>/dev/null  # Copy template to source directory
            OUTPATH=../src/assets/${MODID}/lang/${LANGFILE} # Links OUTPATH to destination of previous copy command
            for LINE in $(sed -n '=' ${OUTPATH}); do    # Loops through each line in template based on number

                ORIGIN=$(sed -n "${LINE}p" ${OUTPATH})  # Sets ORIGIN as text in currently looped line
                if [[ ${ORIGIN} =~ __ ]]; then  # Check if current line contains the "__" activation switch

                    SEARCH=$(sed "s~: \"§.__\",~~" <<< ${ORIGIN} | grep -f - ${LANGPATH} | grep -o '".*":')   # Strips formatting from template key, then searches for the corresponding key in reference, then greps the translation text
                    if ! [ -z "$SEARCH" ]; then # Check if SEARCH is of nonzero length

                        if grep -q ${SEARCH} ${OUTPATH}; then

                            REPLACE=$(sed "s~: \"§.__\",~~" <<< ${ORIGIN} | grep -f - ${LANGPATH} | grep -o ': ".*"' | sed -e 's~: "~~;s~"~~')  # Strips translation line of unwanted formatting
                            sed -i "${LINE}s~__~$(printf %q "${REPLACE}")~" ${OUTPATH}  # Adds translation line to output file. Printf is used to preserve slashes and other formatting.
                        fi
                    fi
                fi
            done
        done
    done
done

echo "Removing untranslated keys..."
sed -i "/__/d" ../src/*/*/lang/*.json   # Remove untranslated lines

echo "Converting pre-format 4 files..."
for MODPATH in ../src/3/*/lang; do  # Loops through available destination directories

    MODID=$(sed "s~/lang~~" <<< ${MODPATH})
    MODID=$(basename ${MODID})
    for INPATH in ../src/assets/${MODID}/lang/*.json; do    # Loops through previously generated files

        if grep -qE '_.{,4}.json' <<< ${INPATH}; then   # Checks for valid files (ones with underscores)

            FILE=$(basename ${INPATH})
            OUTPATH=../src/3/${MODID}/lang/${FILE%json}lang # Export path
            for LINE in $(sed -n '=' ${INPATH}); do # Loop for lines in reference file

                ORIGIN=$(sed -n "${LINE}p" ${INPATH})   # Sets ORIGIN as actual text in current line
                echo -e "${ORIGIN}" >> ${OUTPATH}       # Concerts any unicode addresses to symbols and adds to new line in destination
                sed -i "/{/d;/}/d" ${OUTPATH}           # Remove leading and tailing line
                sed -i "s~\": \"~=~;s~,~~" ${OUTPATH}   # First command to remove formatting
                sed -i "s~\"~~g;s~^ *~~g" ${OUTPATH}    # Second command to remove formatting
            done
        fi
    done
done

# Copy files created in format 3 to format 2 and make area code uppercase
echo "Converting pre-format 3 files..."
for MODPATH in ../src/2/*/lang; do

    MODID=$(sed "s~/lang~~" <<< ${MODPATH})
    MODID=$(basename ${MODID})
    for FILEPATH in ../src/3/${MODID}/lang/*.lang; do

        FILE=$(basename ${FILEPATH})
        MODIFY=$(grep -o _.\*\\. <<< ${FILE})
        COPY=$(sed "s~${MODIFY}~${MODIFY^^}~" <<< ${FILE})
        cp $FILEPATH ../src/2/${MODID}/lang/$COPY
    done
done

echo
echo ":: Finished generating language files."
echo

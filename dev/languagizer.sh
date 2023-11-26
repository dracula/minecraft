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

# Check deps
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

for VER in ./lang/*/; do

    for MODPATH in ${VER}/*/; do

        MODID=$(basename ${MODPATH})
        for LANGPATH in ${MODPATH}/*.json; do

            LANGFILE=$(basename $LANGPATH)
            cp -n ./lang/${MODID}.json ../src/assets/${MODID}/lang/${LANGFILE} 2>/dev/null
            OUTPATH=../src/assets/${MODID}/lang/${LANGFILE}
            for LINE in $(sed -n '=' ${OUTPATH}); do

                ORIGIN=$(sed -n "${LINE}p" ${OUTPATH})
                if [[ ${ORIGIN} =~ __ ]]; then

                    TEST=$(sed "s~: \"§.__\",~~" <<< ${ORIGIN} | grep -f - ${LANGPATH} | grep -o '".*":')
                    if ! [ -z "$TEST" ]; then

                        if grep -q ${TEST} ${OUTPATH}; then

                            REPLACE=$(sed "s~: \"§.__\",~~" <<< ${ORIGIN} | grep -f - ${LANGPATH} | grep -o ': ".*"' | sed -e 's~: "~~;s~"~~')
                            sed -i "${LINE}s~__~$(printf %q "${REPLACE}")~" ${OUTPATH}
                        fi
                    fi
                fi
            done
        done
    done
done

sed -i "s~__~\&~" ../src/assets/*/lang/*.json

for FILE in ../src/assets/*/lang/*.json; do

    if grep -qE '_.{,4}.json' <<< ${FILE}; then

        cp ${FILE} ${FILE%json}lang
        sed -i "/{/d;/}/d" ${FILE%json}lang
        sed -i "s~\": \"~=~;s~,~~" ${FILE%json}lang
        sed -i "s~\"~~g;s~^ *~~g" ${FILE%json}lang
    fi
done

for FILE in ../src/assets/*/lang/*.lang; do

    MODIFY=$(grep -o _.\*\\. <<< ${FILE})
    COPY=$(sed "s~${MODIFY}~${MODIFY^^}~" <<< ${FILE})
    cp $FILE $COPY 2>/dev/null
done

echo
echo ":: Finished generating language files."
echo

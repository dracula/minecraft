#!/usr/bin/awk -f

{
  edit = $0
  if ($0 ~ /^[[:space:]]*d=/) {
    while (match(edit, /[0-9]+\.[0-9]+/)) {
      num = substr(edit, RSTART, RLENGTH)
      rounded = sprintf("%.0f", num)
      edit = substr(edit, 1, RSTART - 1) rounded substr(edit, RSTART + RLENGTH)
    }
    print edit
  } else {
    print $0
  }
}

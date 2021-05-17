#!/bin/bash

absolute_path=$(realpath $1)
echo "$absolute_path"
base_path=$2
echo "$base_path"
exit_code=0
link_errors=""

while IFS= read -r -d $'\0' file; do
    link_check_result=$(node_modules/markdown-link-check/markdown-link-check -c config.json $file 2>&1)
    link_check_exit_code=$?
    echo "$link_check_result"
    if [ "$link_check_exit_code" == 1 ]; then
        link_check_errors=$(echo "$link_check_result" | grep -A999999999 'ERROR:' | tail -n +2)
        # echo "$link_check_errors"
        exit_code=1
        link_errors=$(printf "$link_errors\n\n$file\n$link_check_errors")
       # special output for problem matcher
        while IFS= read -r link_error; do
            # echo "ERROR:$file:$link_error"
            echo "::error file=$(realpath --relative-to="$base_path" "$file"),line=0,col=0::$link_error"
        done < <(echo "$link_check_errors")
     fi
done < <(find $absolute_path -name '*.md' -print0) # use null seperator to allow for spaces in filename

# echo "$link_errors"
exit $exit_code

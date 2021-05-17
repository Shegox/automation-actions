#!/bin/bash

absolute_path=$(realpath $1)
base_path=$2
action_path=$3
exit_code=0
link_errors=""

while IFS= read -r -d $'\0' file; do
    link_check_result=$($action_path/node_modules/markdown-link-check/markdown-link-check -c $action_path/config.json $file 2>&1)
    link_check_exit_code=$?
    # echo "$link_check_result"
    if [ "$link_check_exit_code" == 1 ]; then
        link_check_errors=$(echo "$link_check_result" | grep -A999999999 'ERROR:' | tail -n +2)
        # echo "$link_check_errors"
        exit_code=1
        link_errors=$(printf "$link_errors\n\n$file\n$link_check_errors")
        relative_file=$(realpath --relative-to="$base_path" "$file")
        # special output for problem matcher
        link_errors_for_annotation=""
        echo "$relative_file"
        while IFS= read -r link_error; do
            # echo "ERROR:$file:$link_error"
            # echo "$relative_file"
            link_errors_for_annotation=$(printf "$link_errors_for_annotation$link_error%0A")
            # echo "::error file=$relative_file,line=0,col=0::A link in this file seems to be broken.%0A$link_error"
        done < <(echo "$link_check_errors")
        echo "::error file=$relative_file,line=0,col=0::One or more links in this file seems to be broken.%0A$link_errors_for_annotation"

     fi
done < <(find $absolute_path -name '*.md' -print0) # use null seperator to allow for spaces in filename

# echo "$link_errors"
exit $exit_code

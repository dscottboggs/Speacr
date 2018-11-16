#!/bin/sh
set -e

project_dir=/home/scott/Documents/code/espeak.cr
bind_cmd=$project_dir/lib/autobind/autobind
include_dirs="-I/usr/include -I/usr/include/espeak"
out_dir=$project_dir/src/lib_espeak
name="LibEspeak"
module="Espeak"

[ -d "$out_dir" ] || mkdir -p "$out_dir"

bind() {
  CFLAGS="-ferror-limit=-1" "$bind_cmd" \
    "$include_dirs" \
    "--lib-name=$name" \
    "--parent-module=$module" \
    "$1.h" > "$out_dir/`basename "$1"`-generated.cr"
}

bind espeak/speak_lib

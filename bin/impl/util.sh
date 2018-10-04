#! /usr/bin/env bash

# Copyright 2014 Uno authors (see AUTHORS)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function verify_exist_hash() {
  tarball=$1
  expected_hash=$(echo "${2// /}" | tr '[:upper:]' '[:lower:]')

  if [[ ! -f "$DOWNLOADS/$tarball" ]]; then
    print_to_console "The tarball $tarball does not exist in downloads/"
    exit 1
  fi

  local HASH_CMD
  case "${#expected_hash}" in
    32) HASH_CMD='md5sum' ;;
    40) HASH_CMD='shasum -a 1' ;;
    64) HASH_CMD='shasum -a 256' ;;
    128) HASH_CMD='shasum -a 512' ;;
    *)
      print_to_console "Expected checksum ($expected_hash) of $tarball is not an MD5, SHA1, SHA256, or SHA512 sum"
      exit 1
      ;;
  esac
  actual_hash=$($HASH_CMD "$DOWNLOADS/$tarball" | awk '{print $1}')

  if [[ "$actual_hash" != "$expected_hash" ]]; then
    print_to_console "The actual checksum ($actual_hash) of $tarball does not match the expected checksum ($expected_hash)"
    exit 1
  fi
}

# Takes directory variables as arguments
function check_dirs() {
  for arg in "$@"; do
    if [[ ! -d "${!arg}" ]]; then
      print_to_console "$arg=${!arg} is not a valid directory. Please make sure it exists"
      exit 1
    fi
  done
}

function run_plugins() {
  for plugin in $UNO_PLUGINS
  do
    echo "Running $plugin plugin"
    plugin_script="${UNO_HOME}/plugins/${plugin}.sh"
    if [[ ! -f "$plugin_script" ]]; then
      echo "Plugin does not exist: $plugin_script"
      exit 1
    fi
    $plugin_script
  done  
}

function install_component() {
  local component; component=$(echo "$1" | tr '[:upper:] ' '[:lower:]-')
  shift
  "$UNO_HOME/bin/impl/install/$component.sh" "$@"
}

function run_component() {
  local component; component=$(echo "$1" | tr '[:upper:] ' '[:lower:]-')
  local logs; logs="$LOGS_DIR/setup"
  mkdir -p "$logs"
  shift
  "$UNO_HOME/bin/impl/run/$component.sh" "$component" "$@" 1>"$logs/${component}.out" 2>"$logs/${component}.err"
}

function setup_component() {
  install_component $1
  run_component $1
}

function save_console_fd {
  if [[ -z "$UNO_CONSOLE_FD" && "$OSTYPE" != "darwin"* ]]; then
    # Allocate an unused file descriptor and make it dup stdout
    # https://stackoverflow.com/a/41620630/7298689
    exec {UNO_CONSOLE_FD}>&1
    export UNO_CONSOLE_FD
  fi
}

function print_to_console {
  if [[ -z "$UNO_CONSOLE_FD" ]]; then
    echo "$@"
  else
    echo "$@" >&${UNO_CONSOLE_FD}
  fi
}

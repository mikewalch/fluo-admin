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

source "$UNO_HOME"/bin/impl/util.sh

[[ -n $LOGS_DIR ]] && rm -f "$LOGS_DIR"/setup/*.{out,err}
echo "Beginning setup (detailed logs in $LOGS_DIR/setup)..."
save_console_fd

case "$1" in
  all)
    install_component fluo
    run_plugins
    run_component fluo
    setup_component fluo
    setup_component spark
    setup_component metrics
    ;;
  accumulo|fluo)
    install_component "$1" "$2"
    run_plugins
    run_component "$1" "$2"
    ;;
  spark|metrics|hadoop|zookeeper|fluo-yarn)
    setup_component "$1"
    ;;
  *)
    echo "Usage: uno setup <component> [--no-deps]"
    echo -e "\nPossible components:\n"
    echo "    all        Sets up all of the following components"
    echo "    accumulo   Sets up Apache Accumulo and its dependencies (Hadoop & ZooKeeper)"
    echo "    spark      Sets up Apache Spark"
    echo "    fluo       Sets up Apache Fluo and its dependencies (Accumulo, Hadoop, & ZooKeeper)"
    echo "    fluo-yarn  Sets up Apache Fluo YARN and its dependencies (Fluo, Accumulo, Hadoop, & ZooKeeper)"
    echo -e "    metrics    Sets up metrics service (InfluxDB + Grafana)\n"
    echo "Options:"
    echo "    --no-deps  Dependencies will be setup unless this option is specified. Only works for fluo & accumulo components."
    exit 1
    ;;
esac

if [[ "$?" == 0 ]]; then
  echo "Setup complete."
else
  echo "Setup failed!"
  false
fi

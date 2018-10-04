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

pkill -f org.apache.spark.deploy.history.HistoryServer

# stop if any command fails
set -e

export SPARK_LOG_DIR=$LOGS_DIR/spark
"$SPARK_HOME"/sbin/start-history-server.sh

print_to_console "Apache Spark History Server is running"
print_to_console "  * view at http://localhost:18080/"

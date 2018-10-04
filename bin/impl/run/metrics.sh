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

if [[ "$OSTYPE" == "darwin"* ]]; then
  print_to_console "The metrics services (InfluxDB and Grafana) are not supported on Mac OS X at this time."
  exit 1
fi

pkill -f influxdb
pkill -f grafana-server

"$INFLUXDB_HOME"/bin/influxd -config "$INFLUXDB_HOME"/influxdb.conf &> "$LOGS_DIR"/metrics/influxdb.log &

"$GRAFANA_HOME"/bin/grafana-server -homepath="$GRAFANA_HOME" 2> /dev/null &

sleep 10

if [[ -d "$FLUO_HOME" ]]; then
  "$INFLUXDB_HOME"/bin/influx -import -path "$FLUO_HOME"/contrib/influxdb/fluo_metrics_setup.txt
fi

# allow commands to fail
set +e

sleep 5

function add_datasource() {
  retcode=1
  while [[ $retcode != 0 ]];  do
    curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' \
      --data-binary "$1"
    retcode=$?
    if [[ $retcode != 0 ]]; then
      print_to_console "Failed to add Grafana data source. Retrying in 5 sec.."
      sleep 5
    fi
  done
}

if [[ -d "$ACCUMULO_HOME" ]]; then
  accumulo_data='{"name":"accumulo_metrics","type":"influxdb","url":"http://'
  accumulo_data+=$UNO_HOST
  accumulo_data+=':8086","access":"direct","isDefault":true,"database":"accumulo_metrics","user":"accumulo","password":"secret"}'
  add_datasource $accumulo_data
fi

if [[ -d "$FLUO_HOME" ]]; then
  fluo_data='{"name":"fluo_metrics","type":"influxdb","url":"http://'
  fluo_data+=$UNO_HOST
  fluo_data+=':8086","access":"direct","isDefault":false,"database":"fluo_metrics","user":"fluo","password":"secret"}'
  add_datasource $fluo_data
fi

print_to_console "InfluxDB $INFLUXDB_VERSION is running"
print_to_console "Grafana $GRAFANA_VERSION is running"
print_to_console "    * UI: http://$UNO_HOST:3000/"

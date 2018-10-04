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

# verify downloaded tarballs
INFLUXDB_TARBALL=influxdb_"$INFLUXDB_VERSION"_x86_64.tar.gz
GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".linux-x64.tar.gz
verify_exist_hash "$INFLUXDB_TARBALL" "$INFLUXDB_HASH"
verify_exist_hash "$GRAFANA_TARBALL" "$GRAFANA_HASH"

# make sure built tarballs exist
INFLUXDB_TARBALL=influxdb-"$INFLUXDB_VERSION".tar.gz
GRAFANA_TARBALL=grafana-"$GRAFANA_VERSION".tar.gz
if [[ ! -f "$DOWNLOADS/build/$INFLUXDB_TARBALL" ]]; then
  print_to_console "InfluxDB tarball $INFLUXDB_TARBALL does not exists in downloads/build/"
  exit 1
fi
if [[ ! -f "$DOWNLOADS/build/$GRAFANA_TARBALL" ]]; then
  print_to_console "Grafana tarball $GRAFANA_TARBALL does not exists in downloads/build"
  exit 1
fi

# stop if any command fails
set -e

rm -rf "$INSTALL"/influxdb-*
rm -rf "$INSTALL"/grafana-*
rm -f "$LOGS_DIR"/metrics/*
rm -rf "$DATA_DIR"/influxdb
mkdir -p "$LOGS_DIR"/metrics

echo "Installing InfluxDB $INFLUXDB_VERSION to $INFLUXDB_HOME"

tar xzf "$DOWNLOADS/build/$INFLUXDB_TARBALL" -C "$INSTALL"
"$INFLUXDB_HOME"/bin/influxd config -config "$UNO_HOME"/conf/influxdb/influxdb.conf > "$INFLUXDB_HOME"/influxdb.conf
if [[ ! -f "$INFLUXDB_HOME"/influxdb.conf ]]; then
  print_to_console "Failed to create $INFLUXDB_HOME/influxdb.conf"
  exit 1
fi
$SED "s#DATA_DIR#$DATA_DIR#g" "$INFLUXDB_HOME"/influxdb.conf

echo "Installing Grafana $GRAFANA_VERSION to $GRAFANA_HOME"

tar xzf "$DOWNLOADS/build/$GRAFANA_TARBALL" -C "$INSTALL"
cp "$UNO_HOME"/conf/grafana/custom.ini "$GRAFANA_HOME"/conf/
$SED "s#GRAFANA_HOME#$GRAFANA_HOME#g" "$GRAFANA_HOME"/conf/custom.ini
$SED "s#LOGS_DIR#$LOGS_DIR#g" "$GRAFANA_HOME"/conf/custom.ini
mkdir "$GRAFANA_HOME"/dashboards

if [[ -d "$ACCUMULO_HOME" ]]; then
  echo "Configuring Accumulo metrics"
  cp "$UNO_HOME"/conf/grafana/accumulo-dashboard.json "$GRAFANA_HOME"/dashboards/
  conf=$ACCUMULO_HOME/conf
  metrics_props=hadoop-metrics2-accumulo.properties
  cp "$conf"/templates/"$metrics_props" "$conf"/
  $SED "/accumulo.sink.graphite/d" "$conf"/"$metrics_props"
  {
    echo "accumulo.sink.graphite.class=org.apache.hadoop.metrics2.sink.GraphiteSink"
    echo "accumulo.sink.graphite.server_host=localhost"
    echo "accumulo.sink.graphite.server_port=2004"
    echo "accumulo.sink.graphite.metrics_prefix=accumulo"
  } >> "$conf"/"$metrics_props"
fi

if [[ -d "$FLUO_HOME" ]]; then
  echo "Configuring Fluo metrics"
  cp "$FLUO_HOME"/contrib/grafana/* "$GRAFANA_HOME"/dashboards/
  if [[ $FLUO_VERSION =~ ^1\.[0-1].*$ ]]; then
    FLUO_PROPS=$FLUO_HOME/conf/fluo.properties
  else
    FLUO_PROPS=$FLUO_HOME/conf/fluo-app.properties
  fi
  $SED "/fluo.metrics.reporter.graphite/d" "$FLUO_PROPS"
  {
    echo "fluo.metrics.reporter.graphite.enable=true"
    echo "fluo.metrics.reporter.graphite.host=$UNO_HOST"
    echo "fluo.metrics.reporter.graphite.port=2003"
    echo "fluo.metrics.reporter.graphite.frequency=30"
  } >> "$FLUO_PROPS"
fi

stty sane

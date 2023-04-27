#!/bin/bash

# define the directory where the spigot plugins are located
PLUGIN_DIR="./../plugins"

# check if the plugin directory exists
if [ ! -d "$PLUGIN_DIR" ]; then
  echo "Error: Plugin directory $PLUGIN_DIR not found!"
  exit 1
fi

# define the path to the config file
CONFIG_FILE="./ignoredplugins.config"

# create or clear the update log file
if [ -f ./update.log ]; then
  > ./update.log
  echo "Info: update.log already exists, clearing..."
else
  touch ./update.log
  echo "Info: Creating update.log..."
fi

# define the urlencode function
urlencode() {
  local data
  if [ "$#" -eq "1" ]; then
    data=$(curl -s -o /dev/null -w %{url_effective} --get --data-urlencode "$1" "")
    echo "${data##/?}"
  else
    echo "Usage: urlencode <string>"
  fi
}

# check for updates for all plugins
for plugin in "$PLUGIN_DIR"/*.jar; do
  # get the plugin name (without the .jar extension)
  plugin_name=$(basename "$plugin" .jar)

  # check if the plugin is in the ignore list
  if grep -q "^$plugin_name$" "$CONFIG_FILE"; then
    echo "Skipping $plugin_name (ignored)"
    continue
  fi

  # get the latest version of the plugin from Spigot
  latest_version=$(curl -s "https://api.spigotmc.org/simple/repositories/spigot/content/$plugin_name/" | grep -o '<a href="[^"]*.jar">' | sed -E 's/^.*\/([^\/]+)\.jar">.*$/\1/')

  # check if the download was successful
  if [ -z "$latest_version" ]; then
    echo "Error getting version for $plugin_name"
    continue
  fi

  # check if the plugin is up-to-date
  if echo "$plugin" | grep -q "$latest_version"; then
    echo "$plugin_name is up-to-date"
    continue
  fi

  # download the latest version of the plugin
  curl -s "https://cdn.spigotmc.org/repositories/spigot/content/$plugin_name/$plugin_name-$latest_version.jar" -o "$PLUGIN_DIR/$plugin_name.$latest_version.jar.new"

  # check if the download was successful
  if [ $? -ne 0 ]; then
    echo "Error downloading $plugin_name"
    continue
  fi

  # backup the old plugin jar only if an update is found
  mv "$plugin" "$plugin.bak"

  # replace the old plugin jar with the new one
  mv "$plugin_name.$latest_version.jar.new" "$plugin"

  # check if the update was successful
  if [ $? -eq 0 ]; then
    echo "Updated $plugin_name to $latest_version" >> ./update.log
  else
    echo "Error updating $plugin_name to $latest_version"
  fi
done
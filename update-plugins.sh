#!/bin/bash

# define the directory where the spigot plugins are located
PLUGIN_DIR="/path/to/spigot/plugins"

# define the path to the config file
CONFIG_FILE="./ignoredplugins.config"

# create the update log file (if it doesn't exist)
touch ./update.log

# check for updates for all plugins
for plugin in "$PLUGIN_DIR"/*.jar; do
  # get the plugin name (without the .jar extension)
  plugin_name=$(basename "$plugin" .jar)

  # check if the plugin is in the ignore list
  if grep -q "^$plugin_name$" "$CONFIG_FILE"; then
    echo "Skipping $plugin_name (ignored)"
    continue
  fi

  # get the latest version of the plugin
  latest_version=$(curl -s "https://api.spiget.org/v2/resources/$plugin_name/versions/latest" | grep -o '"name":"[^"]*"' | sed 's/"name":"\(.*\)"/\1/')

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
  curl -s "https://api.spiget.org/v2/resources/$plugin_name/versions/latest/download" -o "$PLUGIN_DIR/$plugin_name.$latest_version.jar.new"

  # check if the download was successful
  if [ $? -ne 0 ]; then
    echo "Error downloading $plugin_name"
    continue
  fi

  # backup the old plugin jar only if an update is found
  mv "$plugin" "$plugin.bak"
  
  # replace the old plugin jar with the new one
  mv "$PLUGIN_DIR/$plugin_name.$latest_version.jar" "$plugin"

  # log the update to the update log file
  echo "Updated $plugin_name from $(basename "$plugin") to $(basename "$plugin.bak")" >> ./update.log
done

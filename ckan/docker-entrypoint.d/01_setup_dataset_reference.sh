#!/bin/bash

if [[ $CKAN__PLUGINS == *"dataset_reference"* ]]; then
   # Update database schema
    ckan -c $CKAN_INI db upgrade -p dataset_reference
fi

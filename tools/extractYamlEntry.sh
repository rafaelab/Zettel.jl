#!/usr/bin/env bash

# yq is not installed by default.

# $1: key to extract
# $2: input yaml file

key="$1" yq '.[] | select(.key == strenv(key))' "$2"

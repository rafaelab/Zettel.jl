#!/usr/bin/env bash


jq --arg key "$1" '[.[] | select(.key == $key)]' "$2"
#!/usr/bin/env bash

while getopts "e:f:d:" opt; do
    case $opt in
      f) pidFile="$OPTARG"
    esac
done

if [ -z "$pidFile" ]; then
    printf "No pidFile was provided. Provide one with -f."
    exit
fi

sudo rm "$pidFile"
sudo touch "$pidFile"

DIR="$(dirname "${BASH_SOURCE[0]}")"
cd "$DIR" || exit

if [ "$(git rev-parse --abbrev-ref HEAD)" = "master" ]; then
	vapor run --release=true & echo $! > "$pidFile"
else
	vapor run --release=false & echo $! > "$pidFile"
fi

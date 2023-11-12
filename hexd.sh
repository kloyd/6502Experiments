#!/usr/bin/env zsh
hexdump -e '"1%03_ax: " 16/1 "%02X " "\n"' a.out | awk '{print toupper($0)}'


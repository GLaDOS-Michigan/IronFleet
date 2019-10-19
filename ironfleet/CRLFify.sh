#!/bin/bash

awk 'sub("$", "\r")' $1 > $2
echo "Created " $2 "With CRLF line ending encoding"
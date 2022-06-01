#!/bin/bash

for f in $(ls pgsrc); do
  ./pgfmt.lua $(lua -e "s = '$f'; print(s:sub(1,1):upper() .. s:sub(2))") pgsrc/$f $f.html
done

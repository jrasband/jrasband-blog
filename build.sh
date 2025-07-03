#!/bin/sh

# Remove last build's files
rm -rf public/ .packages/

# Make a new build of the website
emacs -Q --script publish.el

@ECHO OFF

git gc && git prune

git submodule foreach --recursive git gc && git prune

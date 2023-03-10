## Summary

This program is one of the larger examples from my x86-64 Linux Zig library. The
default configuration of this program will pretty print file system information
to standard output in a recursive tree structure. 

## Build
```sh
git clone --recursive "https://github.com/amp-59/treez" "treez";
cd "treez";
sh "zig_lib/support/switch_build_runner.sh";
zig build treez;
sh "zig_lib/support/switch_build_runner.sh";
```

## Notes

Running the script `switch_build_runner.sh` will move the existing standard
library build runner to a backup location in the Zig install directory and
create a symbolic link to my Zig library's build runner.

Running the script a second time will remove this symbolic link and restore the
standard library build runner. In case the script is run consecutively from two
different repositories, the existing symbolic link will be removed and replaced
with a symbolic link to the build runner in the second repository.

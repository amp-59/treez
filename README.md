## Summary

This program is one of the larger examples from my x86-64 Linux Zig library. The
default configuration of this program will pretty print file system information
to standard output in a recursive tree structure. 

There are a few build options and runtime flags which alter the appearance of
the output.

The build options are global constants in `src/main.zig`, after a commented
line `// Config:`.

Runtime flags are given to allow switching from the default behaviour. These can
be listed with `treez --help`.

## Previews

Basic tree:

![alt text](images/colour_tree_u8.png?raw=true)


Pretty tree: `use_wide_arrows = true`

![alt text](images/colour_tree.png?raw=true)


No colour: `colour_default = true` and `--no-colour` or
           `colour_default = false`

![alt text](images/no_colour_tree_u8.png?raw=true)


Plain mode: `print_plain = true`

![alt text](images/colour_plain.png?raw=true)


## Build

```sh
git clone --recursive "https://github.com/amp-59/treez" treez;
cd treez;
zig build --build-runner zig_lib/build_runner.zig treez;
```

## Toggling build runner

```sh
./zig_lib/support/switch_build_runner.sh;
```

![alt text](images/zl_std_std_zl.png?raw=true)

Running the script `switch_build_runner.sh` will move the existing standard
library build runner to a backup location in the Zig install directory and
create a symbolic link to my Zig library's build runner.

Running the script a second time will remove this symbolic link and restore the
standard library build runner. In case the script is run consecutively from two
different repositories, the existing symbolic link will be removed and replaced
with a symbolic link to the build runner in the second repository.

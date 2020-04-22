# Beatcopy

A utility to make installing Beatsaber songs easier. Beatcopy will watch a folder for new **zip** files to appear and will extract them into their own folder in the destination directory. If folder creation and extract was successful, the zip file is deleted.

## Usage

```
# Build beatcopy
mix escript.build

# Run
./beatcopy <folder to watch> <folder to install into>
```

## TODO

- Add option flags (no cleanup, directory creation options, logging)
- Add unit testing
- Add documentation
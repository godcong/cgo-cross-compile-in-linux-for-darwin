# cgo-cross-compile-in-linux-for-darwin

## Usage

- First run the ./build-oclang.sh to make build environment
- After the building you can do anything you need like go

```
   GOOS=darwin GOARCH=amd64 ./go.sh build -o xxx ./path/to/your/project/main.go
   GOOS=darwin GOARCH=arm64 ./go.sh build -o xxx ./path/to/your/project/main.go
```

## PS
This Shell will generate an Apple compilation environment for you.
And after generating and configuring the compiled environment, the configuration will be exported to the environment variable
in `build-oclang.sh` will export:
```
  echo "export PATH=$OSXCROSS_PATH/target/bin/:$PATH" >>/etc/profile
  echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >>/etc/profile
```
Then `go.sh` will used `TOOLCHAIN` path point to `osxcross/target/bin`:
```
readonly TOOLCHAIN="$(pwd)/../build/osxcross/target/bin"
```
You can also change the TOOLCHAIN path to absolute path,then copy the `go.sh` to the system path for used at global.

## Thanks to
https://github.com/techknowlogick/xgo
This Shell is a reference to the xgo implementation, minus the Docker environment deployment.

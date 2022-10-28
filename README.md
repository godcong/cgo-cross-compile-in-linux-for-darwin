# cgo-cross-compile-in-linux-for-darwin

## Usage

- First run the ./build-oclang.sh to make build environment
- After the building you can do anything you need like go

```
   GOOS=darwin GOARCH=amd64 ./go.sh build -o xxx ./path/to/your/project/main.go
   GOOS=darwin GOARCH=arm64 ./go.sh build -o xxx ./path/to/your/project/main.go
```
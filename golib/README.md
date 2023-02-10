# golib Golang Library)

### Prepare

```bash
# Install gomodile
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init

# Prepare manhuagui backend source code
git clone git@github.com:Aoi-hosizora/manhuagui_api
cd manhuagui_api
git checkout 0fb754106d9e80d8cd725a6cc99144b7d84f4457
mv src ..
mv go.mod ..
mv go.sum ..
rm manhuagui_api/ -rf

# Build library to aar
gomobile bind --target android  github.com/Aoi-hosizora/manhuagui-api/src/service
```

### TODO

```
gomobile: C:\Users\AoiHosizora\go\bin\gobind.exe -lang=go,java -outdir=C:\Users\AOIHOS~1\AppData\Local\Temp\gomobile-work-388601535 github.com/Aoi-hosizora/manhuagui-api/src/service failed: exit status 1
functions and methods must return either zero or one values, and optionally an error
unable to import bind: no Go package in golang.org/x/mobile/bind
unable to import bind: no Go package in golang.org/x/mobile/bind
too many result values: func (*github.com/Aoi-hosizora/manhuagui-api/src/service.UserService).CheckLogin(token string) (bool, string, error)
too many result values: func (*github.com/Aoi-hosizora/manhuagui-api/src/service.UserService).CheckLogin(token string) (bool, string, error)
too many result values: func (*github.com/Aoi-hosizora/manhuagui-api/src/service.UserService).CheckLogin(token string) (bool, string, error)
too many result values: func (*github.com/Aoi-hosizora/manhuagui-api/src/service.UserService).CheckLogin(token string) (bool, string, error)
too many result values: func (*github.com/Aoi-hosizora/manhuagui-api/src/service.UserService).CheckLogin(token string) (bool, string, error)
"golang.org/x/mobile/bind" is not found; run go get golang.org/x/mobile/bind: no Go package in golang.org/x/mobile/bind
```
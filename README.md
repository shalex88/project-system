# Project meta-repo

## Native

```bash
#Build
./scripts/build.sh native
#Install to /tmp/project
./scripts/install.sh
```

## Cross

```bash
#Build
./scripts/build.sh cross
#Create package
./scripts/package.sh
#Deploy
./scripts/deploy.sh XX.XX.XX.XX
```

## TODO

- [ ] Mpsoc SDK, what about it?; Decide how to get/install toolchains
- [ ] Support packaging
- [ ] Build files should be simple and generic, the logic should be in toolchain env setup scripts
- [ ] Test the Orin CC binary on the target
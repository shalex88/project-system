# Project meta-repo

## Download

```bash
git clone https://github.com/shalex88/project-system.git --recurse-submodules
```

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
- [ ] Fail if build script does find subdir build.sh files; currently it just skips them
- [ ] Add version argument to build.sh?
- [ ] How to insure only main branch is checked out in submodules?
- [ ] Use cmake install neccessery tools like ninja before build?
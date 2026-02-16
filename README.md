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
# Build all submodules for cross (arm64)
./scripts/build.sh cross

# Create deployment bundle
./scripts/package.sh cross

# Deploy to Orin and forward MPSOC installation
./scripts/deploy.sh --orin fronti@fronti-elsec.local --mpsoc root@frontier-peripheral-ctrl-mpsoc.local
```

## TODO

- [ ] Upload SDKs to Artifactory
- [ ] Add version argument to build.sh?
- [ ] How to insure only main branch is checked out in submodules?
- [ ] Add post install to install neccessery runtime dependencies. gst plugins, nodejs, etc.
- [ ] CI will fail because gst-plugins can't be build natively
- [ ] Migrate to Orin Yocto SDK instead of the docker
- [ ] Use grpc with native resolver to resolve mDNS 'export GRPC_DNS_RESOLVER=native'
- [ ] ./grpcurl_run.sh 172.25.125.10:50051 "core.v1.CoreService/GetInfo" '{"cameraId": 1}' '/mnt/bsp/projects/project-system/submodules/orin/sensor-core/proto/core_service.proto'
- [ ] sudo chown -R $USER:$USER *
- [ ] Triggering video-player through ssh causes errors
- [ ] Use cmake presets
- [ ] Are capabilities properly used? Hence we still expose API of the non existing capabilities?
- [ ] Failed to set zoom min/max becuse of the timeout
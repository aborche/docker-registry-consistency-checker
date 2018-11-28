# docker-registry-consistency-checker
Docker Registry Consistency checker

Sometimes when you run docker registry garbage collector, you can see next message

```
failed to garbage collect: failed to mark: invalid checksum digest format
```

This message says about filesystem problem, for ex: you pull image to registry and free space on volume is over. Pull fails and some garbage data stands on volume.

I'm not found any method for find and cleanup broken hashes from volume.
This script checks all hashes in docker filesystem structure.
If hash of file is wrong - you see error message
This is error message for broken manifest:
```
# /registry/consistency.sh
...................................
==================================================================
[ERROR] Hash missmatch for: /registry/docker/registry/v2/blobs/sha256/71/71db80ff49bfa66a5977343b7b1b3dfbae2a92dd563f63911d149c2b069464d7/data
[ERROR] Original value: 71db80ff49bfa66a5977343b7b1b3dfbae2a92dd563f63911d149c2b069464d7
[ERROR] Computed value: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

Hash used in:
/registry/docker/registry/v2/blobs/sha256/71/71db80ff49bfa66a5977343b7b1b3dfbae2a92dd563f63911d149c2b069464d7
/registry/docker/registry/v2/repositories/ubuntu-test1/_manifests/revisions/sha256/71db80ff49bfa66a5977343b7b1b3dfbae2a92dd563f63911d149c2b069464d7
/registry/docker/registry/v2/repositories/ubuntu-test1/_manifests/tags/latest/index/sha256/71db80ff49bfa66a5977343b7b1b3dfbae2a92dd563f63911d149c2b069464d7
------------------------------------------------------------------
Tags affected:
ubuntu-test1:latest
------------------------------------------------------------------
Layers affected:
------------------------------------------------------------------
Manifests affected:
==================================================================
```
This is error message for broken layer:
```
# /registry/consistency.sh 
.....................
==================================================================
[ERROR] Hash missmatch for: /registry/docker/registry/v2/blobs/sha256/ff/ff175468989f3c84dde3fba71d3672732bc5181cddb0d5d9e4adbec5669db6d2/data
[ERROR] Original value: ff175468989f3c84dde3fba71d3672732bc5181cddb0d5d9e4adbec5669db6d2
[ERROR] Computed value: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

Hash used in:
/registry/docker/registry/v2/blobs/sha256/ff/ff175468989f3c84dde3fba71d3672732bc5181cddb0d5d9e4adbec5669db6d2
/registry/docker/registry/v2/repositories/ubuntu-test1/_layers/sha256/ff175468989f3c84dde3fba71d3672732bc5181cddb0d5d9e4adbec5669db6d2
------------------------------------------------------------------
Tags affected:
------------------------------------------------------------------
Layers affected:
ubuntu-test1:ff175468989f3c84dde3fba71d3672732bc5181cddb0d5d9e4adbec5669db6d2
------------------------------------------------------------------
Manifests affected:

Recurse search in repo ubuntu-test1
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ubuntu-test1:71db80ff49bfa66a5977343b7b1b3dfbae2a92dd563f63911d149c2b069464d7

==================================================================

..............

```

"Recurse seach in repo" means search broken layer in all manifest files in registry


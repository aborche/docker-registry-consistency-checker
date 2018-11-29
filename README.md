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

```
# /registry/consistency.sh
Search docker manifest files in registry tree
Found 8 manifest files

Search orphaned directories in registry tree
Found 0 orphaned directories

Check orphaned hashes in manifest files

Check all data file hashes in registry tree
.
==================================================================
[ERROR] Hash missmatch for: /registry/docker/registry/v2/blobs/sha256/ac/acd85db6e4b18aafa7fcde5480872909bd8e6d5fbd4e5e790ecc09acc06a8b78/data
[ERROR] Original value: acd85db6e4b18aafa7fcde5480872909bd8e6d5fbd4e5e790ecc09acc06a8b78
[ERROR] Computed value: 9baebdc81654513bd66133261681367b4efd0a261e48e35b887f483bf0e3f9cb

Hash location in registry tree:
/registry/docker/registry/v2/blobs/sha256/ac/acd85db6e4b18aafa7fcde5480872909bd8e6d5fbd4e5e790ecc09acc06a8b78
/registry/docker/registry/v2/repositories/ubuntu-test1/_manifests/revisions/sha256/acd85db6e4b18aafa7fcde5480872909bd8e6d5fbd4e5e790ecc09acc06a8b78
------------------------------------------------------------------
Tags affected:
------------------------------------------------------------------
Layers affected:
------------------------------------------------------------------
Manifests affected:

==================================================================

..............................
==================================================================
[ERROR] Hash missmatch for: /registry/docker/registry/v2/blobs/sha256/15/159f0021d73ca240bd2ee0bd6fe9e04e614fe2319cc31742ae6abfb2b9a5e1dd/data
[ERROR] Original value: 159f0021d73ca240bd2ee0bd6fe9e04e614fe2319cc31742ae6abfb2b9a5e1dd
[ERROR] Computed value: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

Hash location in registry tree:
/registry/docker/registry/v2/blobs/sha256/15/159f0021d73ca240bd2ee0bd6fe9e04e614fe2319cc31742ae6abfb2b9a5e1dd
/registry/docker/registry/v2/repositories/ubuntu-16.04/_layers/sha256/159f0021d73ca240bd2ee0bd6fe9e04e614fe2319cc31742ae6abfb2b9a5e1dd
------------------------------------------------------------------
Tags affected:
------------------------------------------------------------------
Layers affected:
ubuntu-16.04:159f0021d73ca240bd2ee0bd6fe9e04e614fe2319cc31742ae6abfb2b9a5e1dd
------------------------------------------------------------------
Manifests affected:

Found 1 broken hashes in manifest /registry/docker/registry/v2/blobs/sha256/4a/4a99e0e9255e387b95989075358832715be61da7e461f6e1031bae6bcbca3264/data
Manifest 4a99e0e9255e387b95989075358832715be61da7e461f6e1031bae6bcbca3264 used in: ubuntu-16.04:python

Recurse search in image ubuntu-16.04
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ubuntu-16.04:4a99e0e9255e387b95989075358832715be61da7e461f6e1031bae6bcbca3264

==================================================================

.
==================================================================
[ERROR] Hash missmatch for: /registry/docker/registry/v2/blobs/sha256/cf/cf44fdfc4edfe9709799e5ff1832512c658af4bebe94c8cb8211d17f914f6309/data
[ERROR] Original value: cf44fdfc4edfe9709799e5ff1832512c658af4bebe94c8cb8211d17f914f6309
[ERROR] Computed value: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

Hash location in registry tree:
/registry/docker/registry/v2/blobs/sha256/cf/cf44fdfc4edfe9709799e5ff1832512c658af4bebe94c8cb8211d17f914f6309
/registry/docker/registry/v2/repositories/ubuntu-14.04/_layers/sha256/cf44fdfc4edfe9709799e5ff1832512c658af4bebe94c8cb8211d17f914f6309
------------------------------------------------------------------
Tags affected:
------------------------------------------------------------------
Layers affected:
ubuntu-14.04:cf44fdfc4edfe9709799e5ff1832512c658af4bebe94c8cb8211d17f914f6309
------------------------------------------------------------------
Manifests affected:

Found 1 broken hashes in manifest /registry/docker/registry/v2/blobs/sha256/f3/f357829eabe9eeb4e14a437cef4ddc154ac9bd2a5e489f35dcdab7b633e3122e/data
Manifest f357829eabe9eeb4e14a437cef4ddc154ac9bd2a5e489f35dcdab7b633e3122e used in: ubuntu-14.04:langs

Recurse search in image ubuntu-14.04
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ubuntu-14.04:f357829eabe9eeb4e14a437cef4ddc154ac9bd2a5e489f35dcdab7b633e3122e

==================================================================
...

```

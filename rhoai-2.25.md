# Additional images:
    - quay.io/modh/caikit-nlp@sha256:4a271eb9e4e980a3549abb74bdcbcd21ccdabe8e8fd145037d200ecff30f3c79
    - quay.io/modh/caikit-tgis-serving@sha256:512e5934fe6031a834107c0a0d83f91306e1129da20b6a5a152f1b291882b231
    - quay.io/modh/odh-trustyai-hf-detector-runtime-rhel9@sha256:3054ed7f537517a68caf6abc49766bd44dc743243fde876bf5db718165c5cb38
    - quay.io/modh/openvino_model_server@sha256:3df0eb32dc1d6a403faa68cb7b53f57c165a9dea7a0310dc4fd66e9480ab44f6
    - quay.io/modh/text-generation-inference@sha256:8419f73485c75b4eb0095d31879cc1a94e2be38a0ece08bc7923cef9cdd9444a
    - quay.io/modh/vllm@sha256:280c1be54ab687df0e88f926389ac03697607b09a95bf9f68859d5b90342e83f
    - quay.io/modh/vllm@sha256:b929e167fd82825833364c8b015af7a5f14611352caf5be9e036774e808c30db
    - quay.io/modh/vllm@sha256:db96c87345f9943a2a3ed81eb7b3e5c25aa7ff327adfdfd4aabf1f4dcd136970
    - quay.io/modh/fms-hf-tuning@sha256:1ad46fe1a23f41f190c49ec2549c64f484c88fe220888a7a5700dd857ca243cc
    - quay.io/modh/ray@sha256:6d076aeb38ab3c34a6a2ef0f58dc667089aa15826fa08a73273c629333e12f1e
    - quay.io/modh/ray@sha256:6091617d45d5681058abecda57e0ee33f57b8855618e2509f1a354a20cc3403c
    - quay.io/modh/training@sha256:f64f7bba3f1020d39491ac84d40d362a52e4822bdc11a33cfff021178b7c4097
    - quay.io/modh/training@sha256:1d0caea3e5d56ff7d672954b1ad511e661df9bdb364d56879961169a4ca8dae0
    - quay.io/modh/training@sha256:883739b576b485d79966d8c894fdd9ebebd226605a2abe8b33593ca67c87a394
    - quay.io/modh/training@sha256:6cdae840fa029da33cccab620367e82404d24ddf67762eb4537a9bffe1af306d
    - registry.redhat.io/rhelai1/instructlab-nvidia-rhel9@sha256:b3dc9af0244aa6b84e6c3ef53e714a316daaefaae67e28de397cd71ee4b2ac7e



# Unsupported Images:
These images are no longer officially supported but are still provided for convenience.
(They may be useful for users who wish to import older resources or maintain compatibility with previous setups.)

# ImageSetConfiguration example:
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 4
storageConfig:
  registry: 
    imageURL: registry.example.com:5000/mirror/oc-mirror-metadata
    skipTLS: false                       
mirror:
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.14
    packages:
    - name: rhods-operator
      channels:
      - name: fast
        minVersion: 2.25.0
        maxVersion: 2.25.0
  additionalImages:   
    - name: quay.io/modh/caikit-nlp@sha256:4a271eb9e4e980a3549abb74bdcbcd21ccdabe8e8fd145037d200ecff30f3c79
    - name: quay.io/modh/caikit-tgis-serving@sha256:512e5934fe6031a834107c0a0d83f91306e1129da20b6a5a152f1b291882b231
    - name: quay.io/modh/odh-trustyai-hf-detector-runtime-rhel9@sha256:3054ed7f537517a68caf6abc49766bd44dc743243fde876bf5db718165c5cb38
    - name: quay.io/modh/openvino_model_server@sha256:3df0eb32dc1d6a403faa68cb7b53f57c165a9dea7a0310dc4fd66e9480ab44f6
    - name: quay.io/modh/text-generation-inference@sha256:8419f73485c75b4eb0095d31879cc1a94e2be38a0ece08bc7923cef9cdd9444a
    - name: quay.io/modh/vllm@sha256:280c1be54ab687df0e88f926389ac03697607b09a95bf9f68859d5b90342e83f
    - name: quay.io/modh/vllm@sha256:b929e167fd82825833364c8b015af7a5f14611352caf5be9e036774e808c30db
    - name: quay.io/modh/vllm@sha256:db96c87345f9943a2a3ed81eb7b3e5c25aa7ff327adfdfd4aabf1f4dcd136970
    - name: quay.io/modh/fms-hf-tuning@sha256:1ad46fe1a23f41f190c49ec2549c64f484c88fe220888a7a5700dd857ca243cc
    - name: quay.io/modh/ray@sha256:6d076aeb38ab3c34a6a2ef0f58dc667089aa15826fa08a73273c629333e12f1e
    - name: quay.io/modh/ray@sha256:6091617d45d5681058abecda57e0ee33f57b8855618e2509f1a354a20cc3403c
    - name: quay.io/modh/training@sha256:f64f7bba3f1020d39491ac84d40d362a52e4822bdc11a33cfff021178b7c4097
    - name: quay.io/modh/training@sha256:1d0caea3e5d56ff7d672954b1ad511e661df9bdb364d56879961169a4ca8dae0
    - name: quay.io/modh/training@sha256:883739b576b485d79966d8c894fdd9ebebd226605a2abe8b33593ca67c87a394
    - name: quay.io/modh/training@sha256:6cdae840fa029da33cccab620367e82404d24ddf67762eb4537a9bffe1af306d
    - name: registry.redhat.io/rhelai1/instructlab-nvidia-rhel9@sha256:b3dc9af0244aa6b84e6c3ef53e714a316daaefaae67e28de397cd71ee4b2ac7e




```

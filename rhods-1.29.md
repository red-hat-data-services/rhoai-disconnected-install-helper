# Additional images:
    - quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - quay.io/modh/cuda-notebooks@sha256:9652f617857603fcfc311b1676ce6ade7b0c9a7431ffdf7e952c26f9eb187d70
    - quay.io/modh/cuda-notebooks@sha256:981c0461244a9b44781ffc6aa0dac60feebf47e55d7536ceb1e2cbc35f91f0c0
    - quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - quay.io/modh/odh-generic-data-science-notebook@sha256:129f187b1aaa517883aab0a49c0b68dacb35cf795ac5be852778350dae874bfb
    - quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - quay.io/modh/odh-minimal-notebook-container@sha256:1df4b79bd1da15e087ab48bfe21e873128a7767eac82c0468ed7490dc6ecd429
    - quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - quay.io/modh/odh-pytorch-notebook@sha256:66d37ba1d8450864b51e109cc18a8ce2ebbfefa5021becacba297c7a52f2f5fb
    - quay.io/modh/odh-trustyai-notebook@sha256:6f012a335fe46841bb0bbcb62656bb12683b6a8febf0c68328da9f667b1295f4
    - quay.io/opendatahub/openvino_model_server@sha256:00fbe9c6a3cb0f178a4b3e13e2351aa1f8b38455c519360f5197bbab4ac46579
    - quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94
    - quay.io/modh/runtime-images@sha256:1dc49192f80f99baf4a1059a6657799433172a25932751f4ab879911e931281c
    - quay.io/modh/runtime-images@sha256:27f12a510a034212ce4d579a970cce7aeeb33ffa32044fe88a262ae15d34e763
    - quay.io/modh/runtime-images@sha256:358e2409e3d958ed72f1287ae05d25c8766f6b1179a64fbbd7b5eb23c754386f
    - quay.io/modh/runtime-images@sha256:494dbd52992b6e0b7432aa7922c96f93cb1fcbc3bbe5c68bca46ddaf6263c6f1
    - quay.io/modh/runtime-images@sha256:dc8679b47d0af5f4b23ec8a987c696afda54b192316b5cbcae0ecb660497f652
    - quay.io/modh/runtime-images@sha256:f233a16ddb9427fd07775881a8ec2206fb6c59858137289fa2e495573bc1623c

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
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.13
    packages:
    - name: rhods-operator
      channels:
      - name: stable
  additionalImages:   
    - name: quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - name: quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - name: quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - name: quay.io/modh/cuda-notebooks@sha256:9652f617857603fcfc311b1676ce6ade7b0c9a7431ffdf7e952c26f9eb187d70
    - name: quay.io/modh/cuda-notebooks@sha256:981c0461244a9b44781ffc6aa0dac60feebf47e55d7536ceb1e2cbc35f91f0c0
    - name: quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:129f187b1aaa517883aab0a49c0b68dacb35cf795ac5be852778350dae874bfb
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:1df4b79bd1da15e087ab48bfe21e873128a7767eac82c0468ed7490dc6ecd429
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - name: quay.io/modh/odh-pytorch-notebook@sha256:66d37ba1d8450864b51e109cc18a8ce2ebbfefa5021becacba297c7a52f2f5fb
    - name: quay.io/modh/odh-trustyai-notebook@sha256:6f012a335fe46841bb0bbcb62656bb12683b6a8febf0c68328da9f667b1295f4
    - name: quay.io/opendatahub/openvino_model_server@sha256:00fbe9c6a3cb0f178a4b3e13e2351aa1f8b38455c519360f5197bbab4ac46579
    - name: quay.io/modh/runtime-images@sha256:1dc49192f80f99baf4a1059a6657799433172a25932751f4ab879911e931281c
    - name: quay.io/modh/runtime-images@sha256:27f12a510a034212ce4d579a970cce7aeeb33ffa32044fe88a262ae15d34e763
    - name: quay.io/modh/runtime-images@sha256:358e2409e3d958ed72f1287ae05d25c8766f6b1179a64fbbd7b5eb23c754386f
    - name: quay.io/modh/runtime-images@sha256:494dbd52992b6e0b7432aa7922c96f93cb1fcbc3bbe5c68bca46ddaf6263c6f1
    - name: quay.io/modh/runtime-images@sha256:dc8679b47d0af5f4b23ec8a987c696afda54b192316b5cbcae0ecb660497f652
    - name: quay.io/modh/runtime-images@sha256:f233a16ddb9427fd07775881a8ec2206fb6c59858137289fa2e495573bc1623c
    - name: quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94
```

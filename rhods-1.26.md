# Additional images:
    - quay.io/modh/odh-generic-data-science-notebook@sha256:46dbee9764ae96d95fb5719446226bf0b86ec1e8cc695ac12df575a352d79f8f
    - quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - quay.io/modh/cuda-notebooks@sha256:a6080e64d9b70683d8f19334d85e5df7d574f260e2923568e1c5d955d2a8bdc5
    - quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - quay.io/modh/odh-minimal-notebook-container@sha256:43c88006d3bf71513b5e265a9bcf09b315aaa2142b6175c0e618829927dbaac2
    - quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - quay.io/modh/odh-pytorch-notebook@sha256:9eb63a61da203178ff2579861a39efedd264447aa45a787d6b7bd9b08c13b1af
    - quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - quay.io/modh/cuda-notebooks@sha256:0070bf826f759be89068133edf73ba73855263c9788624b4f94dd3acb14d23b7
    - quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - quay.io/modh/odh-trustyai-notebook@sha256:f8be3f6622d4bca653568e9c8b43363a842808d4669a3cd397f0d3a4f9a4c165
    - quay.io/modh/openvino-model-server@sha256:c89f76386bc8b59f0748cf173868e5beef21ac7d2f78dada69089c4d37c44116
    - quay.io/modh/must-gather@sha256:5de36f9f89b068ac2f15dae103384a4947a6815f896263cee10d8c9bf24dc219

# ImageSetConfiguration example:
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 4
storageConfig:
  registry: false
    imageURL: registry.example.com:5000/mirror/oc-mirror-metadata
    skipTLS:                         
mirror:
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.12
    packages:
    - name: rhods-operator
      channels:
      - name: stable
  additionalImages:   
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:46dbee9764ae96d95fb5719446226bf0b86ec1e8cc695ac12df575a352d79f8f
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - name: quay.io/modh/cuda-notebooks@sha256:a6080e64d9b70683d8f19334d85e5df7d574f260e2923568e1c5d955d2a8bdc5
    - name: quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:43c88006d3bf71513b5e265a9bcf09b315aaa2142b6175c0e618829927dbaac2
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - name: quay.io/modh/odh-pytorch-notebook@sha256:9eb63a61da203178ff2579861a39efedd264447aa45a787d6b7bd9b08c13b1af
    - name: quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - name: quay.io/modh/cuda-notebooks@sha256:0070bf826f759be89068133edf73ba73855263c9788624b4f94dd3acb14d23b7
    - name: quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - name: quay.io/modh/odh-trustyai-notebook@sha256:f8be3f6622d4bca653568e9c8b43363a842808d4669a3cd397f0d3a4f9a4c165
    - name: quay.io/modh/openvino-model-server@sha256:c89f76386bc8b59f0748cf173868e5beef21ac7d2f78dada69089c4d37c44116
    - name: quay.io/modh/must-gather@sha256:2a5abc16745d72c14c4144d89edbe373d6d56c8b6ce7965fcbed1862519092ab
```

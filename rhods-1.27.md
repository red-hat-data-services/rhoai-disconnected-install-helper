# Additional images:
    - quay.io/modh/odh-generic-data-science-notebook@sha256:b89ff6ecb174e00749ea0fb47abd4909bb992d2b48e95d0e28089a0d7fd83100
    - quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - quay.io/modh/cuda-notebooks@sha256:b899e5160df29ac80c62512bdbc9499e86dcb1843ade11d5c861ba6f2c41cb37
    - quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - quay.io/modh/odh-minimal-notebook-container@sha256:d1b4fd1c24323806749ffdc7f89a8a44ea2077e50f06e13fcdb01fbd94e6cb64
    - quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - quay.io/modh/odh-pytorch-notebook@sha256:f530288fe2536aa13b78fb73d07d3831ff7a24141a56628201be79192566e69f
    - quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - quay.io/modh/cuda-notebooks@sha256:7cd89e5e8612cfa246e8373b1edeeb5c0901bcd6db4421c94eaa40a1589dcd42
    - quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - quay.io/modh/odh-trustyai-notebook@sha256:3ec0568dfee3ee98b0cca694b025db369f1ea79e5db033dff01af53826c44a97
    - quay.io/modh/openvino-model-server@sha256:c89f76386bc8b59f0748cf173868e5beef21ac7d2f78dada69089c4d37c44116
    - quay.io/modh/must-gather@sha256:5de36f9f89b068ac2f15dae103384a4947a6815f896263cee10d8c9bf24dc219

# ImageSetConfiguration example:
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 4
storageConfig:
  registry: true
    imageURL: myregistry
    skipTLS:                         
mirror:
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:myversion
    packages:
    - name: rhods-operator
      channels:
      - name: inestable
  additionalImages:   
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:b89ff6ecb174e00749ea0fb47abd4909bb992d2b48e95d0e28089a0d7fd83100
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - name: quay.io/modh/cuda-notebooks@sha256:b899e5160df29ac80c62512bdbc9499e86dcb1843ade11d5c861ba6f2c41cb37
    - name: quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:d1b4fd1c24323806749ffdc7f89a8a44ea2077e50f06e13fcdb01fbd94e6cb64
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - name: quay.io/modh/odh-pytorch-notebook@sha256:f530288fe2536aa13b78fb73d07d3831ff7a24141a56628201be79192566e69f
    - name: quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - name: quay.io/modh/cuda-notebooks@sha256:7cd89e5e8612cfa246e8373b1edeeb5c0901bcd6db4421c94eaa40a1589dcd42
    - name: quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - name: quay.io/modh/odh-trustyai-notebook@sha256:3ec0568dfee3ee98b0cca694b025db369f1ea79e5db033dff01af53826c44a97
    - name: quay.io/modh/openvino-model-server@sha256:c89f76386bc8b59f0748cf173868e5beef21ac7d2f78dada69089c4d37c44116
    - name: quay.io/modh/must-gather@sha256:5de36f9f89b068ac2f15dae103384a4947a6815f896263cee10d8c9bf24dc219
```

# Additional images:
    - quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - quay.io/modh/fms-hf-tuning@sha256:83f70e981657728ef9929fa50d06fe5c72f364e5ed41a9fc1331e99751f610e8
    - quay.io/modh/ray@sha256:595b3acd10244e33fca1ed5469dccb08df66f470df55ae196f80e56edf35ad5a
    - quay.io/modh/ray@sha256:6b135421b6e756593a58b4df6664f82fc4b55237ca81475f2867518f15fe6d84
    - quay.io/modh/ray@sha256:28a8745be454b0e881ce6c200599ddfcb3366b707a5b53cfa73087d599555158
    - quay.io/modh/ray@sha256:900c35ec2fe4279b958e044c781a179c8cfe0c584e8af16e253814dba01816e6
    - registry.redhat.io/rhoai/odh-workbench-jupyter-minimal-cpu-py311-rhel9@sha256:2b00a5b676b07d4fd6ab894d5dcaeb5bf88ef35bde76cbf3b4c0951987e5aad6
    - registry.redhat.io/rhoai/odh-workbench-jupyter-minimal-cuda-py311-rhel9@sha256:481c5f3749efb85300ed6076a5b05ca5be1ceda17518791db3a67c7b1fa24941
    - registry.redhat.io/rhoai/odh-workbench-jupyter-minimal-rocm-py311-rhel9@sha256:4cc172aab8be2ba278a9525ef0878c68d76963beb9506c8526c07d5b90b1eb58
    - registry.redhat.io/rhoai/odh-workbench-jupyter-datascience-cpu-py311-rhel9@sha256:bd6528eddad7106704c9f78bd25d47bd5a556ecc0e35db317a0e95428be6d025
    - registry.redhat.io/rhoai/odh-workbench-jupyter-pytorch-cuda-py311-rhel9@sha256:384f2ea2df8ccf1978ba633a0b32332e12a4c8d026967ff93e7b8fb0928c8265
    - registry.redhat.io/rhoai/odh-workbench-jupyter-pytorch-rocm-py311-rhel9@sha256:8270d5c58389d0f7ed086336c730060c3792453a4ddc08f0bc622677edd3e0fd
    - registry.redhat.io/rhoai/odh-workbench-jupyter-tensorflow-cuda-py311-rhel9@sha256:a2f863e8df080b683f52453b3a3b8c1f70a50c9bbe9480d7a55da8f0d54fbee2
    - registry.redhat.io/rhoai/odh-workbench-jupyter-tensorflow-rocm-py311-rhel9@sha256:4d1b945221fe7f3e7a486277f27529b9ba2b73b03b9a7e2a3382c133671fcff3
    - registry.redhat.io/rhoai/odh-workbench-jupyter-trustyai-cpu-py311-rhel9@sha256:4331bd07ffb9676a3d9f387b56148e679e0bc50a05dbcc5e693df5aafb097bc0
    - registry.redhat.io/rhoai/odh-workbench-codeserver-datascience-cpu-py311-rhel9@sha256:755f8dacf495f6abb29233edb422ca473ba82cc23370d4fcbaa4f938e90a9c25



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
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.20
    packages:
    - name: rhods-operator
      channels:
      - name: stable
        minVersion: 3.3.1
        maxVersion: 3.3.1
  additionalImages:   
    - name: quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - name: quay.io/modh/fms-hf-tuning@sha256:83f70e981657728ef9929fa50d06fe5c72f364e5ed41a9fc1331e99751f610e8
    - name: quay.io/modh/ray@sha256:595b3acd10244e33fca1ed5469dccb08df66f470df55ae196f80e56edf35ad5a
    - name: quay.io/modh/ray@sha256:6b135421b6e756593a58b4df6664f82fc4b55237ca81475f2867518f15fe6d84
    - name: quay.io/modh/ray@sha256:28a8745be454b0e881ce6c200599ddfcb3366b707a5b53cfa73087d599555158
    - name: quay.io/modh/ray@sha256:900c35ec2fe4279b958e044c781a179c8cfe0c584e8af16e253814dba01816e6
    - name: registry.redhat.io/rhoai/odh-workbench-jupyter-minimal-cpu-py311-rhel9@sha256:2b00a5b676b07d4fd6ab894d5dcaeb5bf88ef35bde76cbf3b4c0951987e5aad6
    - name: registry.redhat.io/rhoai/odh-workbench-jupyter-minimal-cuda-py311-rhel9@sha256:481c5f3749efb85300ed6076a5b05ca5be1ceda17518791db3a67c7b1fa24941
    - name: registry.redhat.io/rhoai/odh-workbench-jupyter-minimal-rocm-py311-rhel9@sha256:4cc172aab8be2ba278a9525ef0878c68d76963beb9506c8526c07d5b90b1eb58
    - name: registry.redhat.io/rhoai/odh-workbench-jupyter-datascience-cpu-py311-rhel9@sha256:bd6528eddad7106704c9f78bd25d47bd5a556ecc0e35db317a0e95428be6d025
    - name: registry.redhat.io/rhoai/odh-workbench-jupyter-pytorch-cuda-py311-rhel9@sha256:384f2ea2df8ccf1978ba633a0b32332e12a4c8d026967ff93e7b8fb0928c8265
    - name: registry.redhat.io/rhoai/odh-workbench-jupyter-pytorch-rocm-py311-rhel9@sha256:8270d5c58389d0f7ed086336c730060c3792453a4ddc08f0bc622677edd3e0fd
    - name: registry.redhat.io/rhoai/odh-workbench-jupyter-tensorflow-cuda-py311-rhel9@sha256:a2f863e8df080b683f52453b3a3b8c1f70a50c9bbe9480d7a55da8f0d54fbee2
    - name: registry.redhat.io/rhoai/odh-workbench-jupyter-tensorflow-rocm-py311-rhel9@sha256:4d1b945221fe7f3e7a486277f27529b9ba2b73b03b9a7e2a3382c133671fcff3
    - name: registry.redhat.io/rhoai/odh-workbench-jupyter-trustyai-cpu-py311-rhel9@sha256:4331bd07ffb9676a3d9f387b56148e679e0bc50a05dbcc5e693df5aafb097bc0
    - name: registry.redhat.io/rhoai/odh-workbench-codeserver-datascience-cpu-py311-rhel9@sha256:755f8dacf495f6abb29233edb422ca473ba82cc23370d4fcbaa4f938e90a9c25



```

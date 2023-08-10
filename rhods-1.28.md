# Additional images:
    - quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - quay.io/modh/cuda-notebooks@sha256:a33b9cff227ad069bf6fea23d50453ff91716056570f20d3b825bad5a61be250
    - quay.io/modh/cuda-notebooks@sha256:cb29aad65658eb314105876cbefa2fa7e9d20337287ecfa3c561e10828725215
    - quay.io/modh/odh-generic-data-science-notebook@sha256:1c888a254b4cc93b4c682d61579f305a789a839f483a88a0672e223ca6789f31
    - quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - quay.io/modh/odh-minimal-notebook-container@sha256:801d03462a8df5cb3c3405e806430bb2f2a88b10df4850204c1f8c1e6cf136e3
    - quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - quay.io/modh/odh-pytorch-notebook@sha256:04b177205fec5017d3dff86a265189d181bc5d7d13d223cf1f41ce9dddc79824
    - quay.io/modh/odh-trustyai-notebook@sha256:9d1243a9608c3a7b2cbd66ff7893049da8a5aaf74751b43ea912d9d645d9c7af
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
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.12
    packages:
    - name: rhods-operator
      channels:
      - name: stable
  additionalImages:   
    - name: quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - name: quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - name: quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - name: quay.io/modh/cuda-notebooks@sha256:a33b9cff227ad069bf6fea23d50453ff91716056570f20d3b825bad5a61be250
    - name: quay.io/modh/cuda-notebooks@sha256:cb29aad65658eb314105876cbefa2fa7e9d20337287ecfa3c561e10828725215
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:1c888a254b4cc93b4c682d61579f305a789a839f483a88a0672e223ca6789f31
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:801d03462a8df5cb3c3405e806430bb2f2a88b10df4850204c1f8c1e6cf136e3
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - name: quay.io/modh/odh-pytorch-notebook@sha256:04b177205fec5017d3dff86a265189d181bc5d7d13d223cf1f41ce9dddc79824
    - name: quay.io/modh/odh-trustyai-notebook@sha256:9d1243a9608c3a7b2cbd66ff7893049da8a5aaf74751b43ea912d9d645d9c7af
    - name: quay.io/opendatahub/openvino_model_server@sha256:00fbe9c6a3cb0f178a4b3e13e2351aa1f8b38455c519360f5197bbab4ac46579
    - name: quay.io/modh/runtime-images@sha256:1dc49192f80f99baf4a1059a6657799433172a25932751f4ab879911e931281c
    - name: quay.io/modh/runtime-images@sha256:27f12a510a034212ce4d579a970cce7aeeb33ffa32044fe88a262ae15d34e763
    - name: quay.io/modh/runtime-images@sha256:358e2409e3d958ed72f1287ae05d25c8766f6b1179a64fbbd7b5eb23c754386f
    - name: quay.io/modh/runtime-images@sha256:494dbd52992b6e0b7432aa7922c96f93cb1fcbc3bbe5c68bca46ddaf6263c6f1
    - name: quay.io/modh/runtime-images@sha256:dc8679b47d0af5f4b23ec8a987c696afda54b192316b5cbcae0ecb660497f652
    - name: quay.io/modh/runtime-images@sha256:f233a16ddb9427fd07775881a8ec2206fb6c59858137289fa2e495573bc1623c
    - name: quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94
```

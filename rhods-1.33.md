# Additional images:
    - quay.io/integreatly/prometheus-blackbox-exporter@sha256:35b9d2c1002201723b7f7a9f54e9406b2ec4b5b0f73d114f47c70e15956103b5
    - quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - quay.io/modh/cuda-notebooks@sha256:25d7e3318850dff7e91c1451cdd7256e78b02f4a1f6d17a37d6c2797923ce4b6
    - quay.io/modh/cuda-notebooks@sha256:2c177921d08563abffc8711b965e4c617aca243146cb4b43ec409a466be10a13
    - quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - quay.io/modh/odh-generic-data-science-notebook@sha256:f1c285f88f37abb0d54efc1941f349dfed824896568bcd359770e15d78fdb9f9
    - quay.io/modh/odh-minimal-notebook-container@sha256:0f7ca48f669a45ce25dc0df4bd89ba7b490f44654d5efa92fc0a20b4899e82ef
    - quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - quay.io/modh/odh-pytorch-notebook@sha256:5e1523a2637beb5f9d3a2aaca65a18febe1b2e08e5e8a724596c38554a317b8a
    - quay.io/modh/odh-trustyai-notebook@sha256:83fa3b34eb237bb7716ac1e021f7b123099574765546f0c450ab06c43df34ad9
    - quay.io/opendatahub/openvino_model_server@sha256:20dbfbaf53d1afbd47c612d953984238cb0e207972ed544a5ea662c2404f276d
    - quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94
    - quay.io/modh/runtime-images@sha256:56b4cdade363b6536c4b62fde7717eba16cf2b9085d48361918b8d65ae9a4c41
    - quay.io/modh/runtime-images@sha256:b14c39fcd1a701ae62d7eebfff41cc4afbd03ade1412d00d8fab1f83b6af9e64
    - quay.io/modh/runtime-images@sha256:b56b923f2f68339ac34eda956ad2cd2f369507b7f60f2264a74d947046077e0c
    - quay.io/modh/runtime-images@sha256:b6000f91c1489ac5acaaac5e2ebf4b3e0a1e78d0c93b13bf41eba827fbf52098
    - quay.io/modh/runtime-images@sha256:cf3535db122d4474949debc931e115f27e5f60b7289cb6e2a55c952b7b4a1726
    - quay.io/modh/runtime-images@sha256:d8bac12fddaf0a3e4d4ac56773a5937d9a03858c961e5b06667cb3d7949c1fd5
    - quay.io/modh/runtime-images@sha256:d9e152ef6ae10b2b721779f8e76fc27f38a1b68a0eb46180af47503b4241ddd6
    - quay.io/modh/runtime-images@sha256:db564cdab5f7b2d305a88cd4a0146d915d1c88988b1b0819803766a79a041693

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
    - name: quay.io/integreatly/prometheus-blackbox-exporter@sha256:35b9d2c1002201723b7f7a9f54e9406b2ec4b5b0f73d114f47c70e15956103b5
    - name: quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - name: quay.io/modh/cuda-notebooks@sha256:25d7e3318850dff7e91c1451cdd7256e78b02f4a1f6d17a37d6c2797923ce4b6
    - name: quay.io/modh/cuda-notebooks@sha256:2c177921d08563abffc8711b965e4c617aca243146cb4b43ec409a466be10a13
    - name: quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - name: quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - name: quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:f1c285f88f37abb0d54efc1941f349dfed824896568bcd359770e15d78fdb9f9
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:0f7ca48f669a45ce25dc0df4bd89ba7b490f44654d5efa92fc0a20b4899e82ef
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - name: quay.io/modh/odh-pytorch-notebook@sha256:5e1523a2637beb5f9d3a2aaca65a18febe1b2e08e5e8a724596c38554a317b8a
    - name: quay.io/modh/odh-trustyai-notebook@sha256:83fa3b34eb237bb7716ac1e021f7b123099574765546f0c450ab06c43df34ad9
    - name: quay.io/opendatahub/openvino_model_server@sha256:20dbfbaf53d1afbd47c612d953984238cb0e207972ed544a5ea662c2404f276d
    - name: quay.io/modh/runtime-images@sha256:56b4cdade363b6536c4b62fde7717eba16cf2b9085d48361918b8d65ae9a4c41
    - name: quay.io/modh/runtime-images@sha256:b14c39fcd1a701ae62d7eebfff41cc4afbd03ade1412d00d8fab1f83b6af9e64
    - name: quay.io/modh/runtime-images@sha256:b56b923f2f68339ac34eda956ad2cd2f369507b7f60f2264a74d947046077e0c
    - name: quay.io/modh/runtime-images@sha256:b6000f91c1489ac5acaaac5e2ebf4b3e0a1e78d0c93b13bf41eba827fbf52098
    - name: quay.io/modh/runtime-images@sha256:cf3535db122d4474949debc931e115f27e5f60b7289cb6e2a55c952b7b4a1726
    - name: quay.io/modh/runtime-images@sha256:d8bac12fddaf0a3e4d4ac56773a5937d9a03858c961e5b06667cb3d7949c1fd5
    - name: quay.io/modh/runtime-images@sha256:d9e152ef6ae10b2b721779f8e76fc27f38a1b68a0eb46180af47503b4241ddd6
    - name: quay.io/modh/runtime-images@sha256:db564cdab5f7b2d305a88cd4a0146d915d1c88988b1b0819803766a79a041693
    - name: quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94
```

# Additional images:
    - quay.io/integreatly/prometheus-blackbox-exporter@sha256:35b9d2c1002201723b7f7a9f54e9406b2ec4b5b0f73d114f47c70e15956103b5
    - quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - quay.io/modh/cuda-notebooks@sha256:5f27f73184d9c10237244ed080180a4c8327e24ece009de67b2c82cc68cd6ae6
    - quay.io/modh/cuda-notebooks@sha256:817564f48843d5d976746aa40bdbc6099aedafbbddad7555bb88194834bc8712
    - quay.io/modh/kserve-agent@sha256:4c112cf2a1c773893a8d22f4ebfa715cf372105dd2ad5fc40efc4fe8f414bb69
    - quay.io/modh/kserve-controller@sha256:fa3f8367dae9527da5c2af08fa5e8c0e9e505ffd3afe5141e707aff4c3de3c86
    - quay.io/modh/kserve-router@sha256:c2da8e104f5e58140ee2d75936cefd9e374a515b070c2309c6d452fb525a0609
    - quay.io/modh/kserve-storage-initializer@sha256:93ffaa9aac1482cdc9cd5ad41a571a1191d52503aa6d573395b1581af7cdc03e
    - quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - quay.io/modh/odh-generic-data-science-notebook@sha256:c22894bf97f563e3f3e6a3e50ce397c05a7d0cb1668bfff2d7b96400cbb42dc6
    - quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - quay.io/modh/odh-minimal-notebook-container@sha256:1d39ca7e4078dbbde0e80f577bca8e226f36708692c5fb21d1e164028351e57f
    - quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - quay.io/modh/odh-pytorch-notebook@sha256:83c0017606aa1811b814e1d2eda94d5cec563bbb86f143eb42c2fd01c2a6faa5
    - quay.io/modh/odh-trustyai-notebook@sha256:b76518657f52037dac376d3f752a10ef83456b5792aa8923082c4d7ac1690dd3
    - quay.io/opendatahub/openvino_model_server@sha256:20dbfbaf53d1afbd47c612d953984238cb0e207972ed544a5ea662c2404f276d
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
    - name: quay.io/integreatly/prometheus-blackbox-exporter@sha256:35b9d2c1002201723b7f7a9f54e9406b2ec4b5b0f73d114f47c70e15956103b5
    - name: quay.io/modh/cuda-notebooks@sha256:2163ba74f602ec4b3049a88dcfa4fe0a8d0fff231090001947da66ef8e75ab9a
    - name: quay.io/modh/cuda-notebooks@sha256:348fa993347f86d1e0913853fb726c584ae8b5181152f0430967d380d68d804f
    - name: quay.io/modh/cuda-notebooks@sha256:492c37fb4b71c07d929ac7963896e074871ded506230fe926cdac21eb1ab9db8
    - name: quay.io/modh/cuda-notebooks@sha256:5f27f73184d9c10237244ed080180a4c8327e24ece009de67b2c82cc68cd6ae6
    - name: quay.io/modh/cuda-notebooks@sha256:817564f48843d5d976746aa40bdbc6099aedafbbddad7555bb88194834bc8712
    - name: quay.io/modh/kserve-agent@sha256:4c112cf2a1c773893a8d22f4ebfa715cf372105dd2ad5fc40efc4fe8f414bb69
    - name: quay.io/modh/kserve-controller@sha256:fa3f8367dae9527da5c2af08fa5e8c0e9e505ffd3afe5141e707aff4c3de3c86
    - name: quay.io/modh/kserve-router@sha256:c2da8e104f5e58140ee2d75936cefd9e374a515b070c2309c6d452fb525a0609
    - name: quay.io/modh/kserve-storage-initializer@sha256:93ffaa9aac1482cdc9cd5ad41a571a1191d52503aa6d573395b1581af7cdc03e
    - name: quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:c22894bf97f563e3f3e6a3e50ce397c05a7d0cb1668bfff2d7b96400cbb42dc6
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:ebb5613e6b53dc4e8efcfe3878b4cd10ccb77c67d12c00d2b8c9d41aeffd7df5
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:1d39ca7e4078dbbde0e80f577bca8e226f36708692c5fb21d1e164028351e57f
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:a5a7738b09a204804e084a45f96360b568b0b9d85709c0ce6742d440ff917183
    - name: quay.io/modh/odh-pytorch-notebook@sha256:83c0017606aa1811b814e1d2eda94d5cec563bbb86f143eb42c2fd01c2a6faa5
    - name: quay.io/modh/odh-trustyai-notebook@sha256:b76518657f52037dac376d3f752a10ef83456b5792aa8923082c4d7ac1690dd3
    - name: quay.io/opendatahub/openvino_model_server@sha256:20dbfbaf53d1afbd47c612d953984238cb0e207972ed544a5ea662c2404f276d
    - name: quay.io/modh/runtime-images@sha256:1dc49192f80f99baf4a1059a6657799433172a25932751f4ab879911e931281c
    - name: quay.io/modh/runtime-images@sha256:27f12a510a034212ce4d579a970cce7aeeb33ffa32044fe88a262ae15d34e763
    - name: quay.io/modh/runtime-images@sha256:358e2409e3d958ed72f1287ae05d25c8766f6b1179a64fbbd7b5eb23c754386f
    - name: quay.io/modh/runtime-images@sha256:494dbd52992b6e0b7432aa7922c96f93cb1fcbc3bbe5c68bca46ddaf6263c6f1
    - name: quay.io/modh/runtime-images@sha256:dc8679b47d0af5f4b23ec8a987c696afda54b192316b5cbcae0ecb660497f652
    - name: quay.io/modh/runtime-images@sha256:f233a16ddb9427fd07775881a8ec2206fb6c59858137289fa2e495573bc1623c
    - name: quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94
```

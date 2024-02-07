# Additional images:
    - quay.io/integreatly/prometheus-blackbox-exporter@sha256:35b9d2c1002201723b7f7a9f54e9406b2ec4b5b0f73d114f47c70e15956103b5
    - quay.io/modh/codeserver@sha256:7b53d6c49b0e18d8907392c19b23ddcdcd4dbf730853ccdf153358ca81b2c523
    - quay.io/modh/cuda-notebooks@sha256:00c53599f5085beedd0debb062652a1856b19921ccf59bd76134471d24c3fa7d
    - quay.io/modh/cuda-notebooks@sha256:491559096894985b138a0e6c400bb9e2db121920e2e1fac821dab07bd7619da3
    - quay.io/modh/cuda-notebooks@sha256:6fadedc5a10f5a914bb7b27cd41bc644392e5757ceaf07d930db884112054265
    - quay.io/modh/cuda-notebooks@sha256:7157cd64ae5b66f2bcf982ec7e1ff4cd587bbd47d8d93f307c97e66097cdc0b8
    - quay.io/modh/cuda-notebooks@sha256:88d80821ff8c5d53526794261d519125d0763b621d824f8c3222127dab7b6cc8
    - quay.io/modh/cuda-notebooks@sha256:f6cdc993b4d493ffaec876abb724ce44b3c6fc37560af974072b346e45ac1a3b
    - quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - quay.io/modh/odh-generic-data-science-notebook@sha256:67a1bbb7dbfc1c4471cdec9263ad9ac064a6b159a4d34601fbe26229acad0f67
    - quay.io/modh/odh-generic-data-science-notebook@sha256:76e6af79c601a323f75a58e7005de0beac66b8cccc3d2b67efb6d11d85f0cfa1
    - quay.io/modh/odh-generic-data-science-notebook@sha256:e2cab24ebe935d87f7596418772f5a97ce6a2e747ba0c1fd4cec08a728e99403
    - quay.io/modh/odh-habana-notebooks@sha256:0f6ae8f0b1ef11896336e7f8611e77ccdb992b49a7942bf27e6bc64d73205d05
    - quay.io/modh/odh-minimal-notebook-container@sha256:39068767eebdf3a127fe8857fbdaca0832cdfef69eed6ec3ff6ed1858029420f
    - quay.io/modh/odh-minimal-notebook-container@sha256:5fc23a778ab9643394f41b1c37e99eeeb7fcf1caf48d9e323fd7cde8cff59a3c
    - quay.io/modh/odh-minimal-notebook-container@sha256:eec50e5518176d5a31da739596a7ddae032d73851f9107846a587442ebd10a82
    - quay.io/modh/odh-pytorch-notebook@sha256:222ec65f81172ace03d09fe7f22fc27da3d1473fd98e6611ec57430e1f31ad35
    - quay.io/modh/odh-pytorch-notebook@sha256:97b346197e6fc568c2eb52cb82e13a206277f27c21e299d1c211997f140f638b
    - quay.io/modh/odh-pytorch-notebook@sha256:b68e0192abf7d46c8c6876d0819b66c6a2d4a1e674f8893f8a71ffdcba96866c
    - quay.io/modh/odh-trustyai-notebook@sha256:8c5e653f6bc6a2050565cf92f397991fbec952dc05cdfea74b65b8fd3047c9d4
    - quay.io/modh/odh-trustyai-notebook@sha256:a9f503a44ea4564df954db4f92edec8e05cef0733acb0a37e9d905a21eb9eb2e
    - quay.io/modh/runtime-images@sha256:0c37b08dc6aaa8d2a43ef85cb0f28777e336a337cb51b471da38bb41f57066a5
    - quay.io/modh/runtime-images@sha256:55e1022903097c7c42c97ec37b195f39c89f412fda4c6ce0297689b2e90cf4f9
    - quay.io/modh/runtime-images@sha256:8afe80b858da5d0eba02d01b84705de7eeb35ff384545ebaa7cc28fddfae0e51
    - quay.io/modh/runtime-images@sha256:b02f0d680c050796d84846a0a2eb542bdce25eb1e77345182ab5ffa86a9e8755
    - quay.io/modh/runtime-images@sha256:d48aa3d8afa03eed988f7cedc93a8730a0406119a6298fad108c65d531902417
    - quay.io/modh/runtime-images@sha256:e00765bd15d35789bf5880b2958356b077068864a09f9a089c49559d0fab6646
    - quay.io/modh/runtime-images@sha256:e1b4351fa6b92d03546eea3e90ad4b71e9f8337f7e5bca82ff92814af3d6ad21
    - quay.io/modh/runtime-images@sha256:f894027b5e31d3f8fae5e6a88d88f7f6727254610761e202ec3946be8df9e627
    - quay.io/modh/openvino_model_server@sha256:007304a96acd654ca5133c50990c6785464fcea44304c8a846d3279b9c83a9d4
    - quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94
    - quay.io/modh/caikit-tgis-serving@sha256:ce6b66bb847608dac5eacd7f9123d2a076a06893d7f37f2da5876a8930527513
    - quay.io/modh/text-generation-inference@sha256:a17a2868644929ee844ceb2778ac3f6db0936824d9b89d11ea7aa059466fcd0b


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
      - name: stable
  additionalImages:   
    - name: quay.io/integreatly/prometheus-blackbox-exporter@sha256:35b9d2c1002201723b7f7a9f54e9406b2ec4b5b0f73d114f47c70e15956103b5
    - name: quay.io/modh/codeserver@sha256:7b53d6c49b0e18d8907392c19b23ddcdcd4dbf730853ccdf153358ca81b2c523
    - name: quay.io/modh/cuda-notebooks@sha256:00c53599f5085beedd0debb062652a1856b19921ccf59bd76134471d24c3fa7d
    - name: quay.io/modh/cuda-notebooks@sha256:491559096894985b138a0e6c400bb9e2db121920e2e1fac821dab07bd7619da3
    - name: quay.io/modh/cuda-notebooks@sha256:6fadedc5a10f5a914bb7b27cd41bc644392e5757ceaf07d930db884112054265
    - name: quay.io/modh/cuda-notebooks@sha256:7157cd64ae5b66f2bcf982ec7e1ff4cd587bbd47d8d93f307c97e66097cdc0b8
    - name: quay.io/modh/cuda-notebooks@sha256:88d80821ff8c5d53526794261d519125d0763b621d824f8c3222127dab7b6cc8
    - name: quay.io/modh/cuda-notebooks@sha256:f6cdc993b4d493ffaec876abb724ce44b3c6fc37560af974072b346e45ac1a3b
    - name: quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:67a1bbb7dbfc1c4471cdec9263ad9ac064a6b159a4d34601fbe26229acad0f67
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:76e6af79c601a323f75a58e7005de0beac66b8cccc3d2b67efb6d11d85f0cfa1
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:e2cab24ebe935d87f7596418772f5a97ce6a2e747ba0c1fd4cec08a728e99403
    - name: quay.io/modh/odh-habana-notebooks@sha256:0f6ae8f0b1ef11896336e7f8611e77ccdb992b49a7942bf27e6bc64d73205d05
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:39068767eebdf3a127fe8857fbdaca0832cdfef69eed6ec3ff6ed1858029420f
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:5fc23a778ab9643394f41b1c37e99eeeb7fcf1caf48d9e323fd7cde8cff59a3c
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:eec50e5518176d5a31da739596a7ddae032d73851f9107846a587442ebd10a82
    - name: quay.io/modh/odh-pytorch-notebook@sha256:222ec65f81172ace03d09fe7f22fc27da3d1473fd98e6611ec57430e1f31ad35
    - name: quay.io/modh/odh-pytorch-notebook@sha256:97b346197e6fc568c2eb52cb82e13a206277f27c21e299d1c211997f140f638b
    - name: quay.io/modh/odh-pytorch-notebook@sha256:b68e0192abf7d46c8c6876d0819b66c6a2d4a1e674f8893f8a71ffdcba96866c
    - name: quay.io/modh/odh-trustyai-notebook@sha256:8c5e653f6bc6a2050565cf92f397991fbec952dc05cdfea74b65b8fd3047c9d4
    - name: quay.io/modh/odh-trustyai-notebook@sha256:a9f503a44ea4564df954db4f92edec8e05cef0733acb0a37e9d905a21eb9eb2e
    - name: quay.io/modh/runtime-images@sha256:0c37b08dc6aaa8d2a43ef85cb0f28777e336a337cb51b471da38bb41f57066a5
    - name: quay.io/modh/runtime-images@sha256:55e1022903097c7c42c97ec37b195f39c89f412fda4c6ce0297689b2e90cf4f9
    - name: quay.io/modh/runtime-images@sha256:8afe80b858da5d0eba02d01b84705de7eeb35ff384545ebaa7cc28fddfae0e51
    - name: quay.io/modh/runtime-images@sha256:b02f0d680c050796d84846a0a2eb542bdce25eb1e77345182ab5ffa86a9e8755
    - name: quay.io/modh/runtime-images@sha256:d48aa3d8afa03eed988f7cedc93a8730a0406119a6298fad108c65d531902417
    - name: quay.io/modh/runtime-images@sha256:e00765bd15d35789bf5880b2958356b077068864a09f9a089c49559d0fab6646
    - name: quay.io/modh/runtime-images@sha256:e1b4351fa6b92d03546eea3e90ad4b71e9f8337f7e5bca82ff92814af3d6ad21
    - name: quay.io/modh/runtime-images@sha256:f894027b5e31d3f8fae5e6a88d88f7f6727254610761e202ec3946be8df9e627
    - name: quay.io/modh/openvino_model_server@sha256:007304a96acd654ca5133c50990c6785464fcea44304c8a846d3279b9c83a9d4
    - name: quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94
    - name: quay.io/modh/caikit-tgis-serving@sha256:ce6b66bb847608dac5eacd7f9123d2a076a06893d7f37f2da5876a8930527513
    - name: quay.io/modh/text-generation-inference@sha256:a17a2868644929ee844ceb2778ac3f6db0936824d9b89d11ea7aa059466fcd0b

```

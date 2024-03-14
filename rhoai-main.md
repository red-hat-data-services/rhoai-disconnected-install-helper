# Additional images:
    - quay.io/integreatly/prometheus-blackbox-exporter@sha256:35b9d2c1002201723b7f7a9f54e9406b2ec4b5b0f73d114f47c70e15956103b5
    - quay.io/modh/codeserver@sha256:17e5bd18d6faaab72754936e4a89c2c596b2dfeb4be0aac6890b6f6145a13d6c
    - quay.io/modh/cuda-notebooks@sha256:00c53599f5085beedd0debb062652a1856b19921ccf59bd76134471d24c3fa7d
    - quay.io/modh/cuda-notebooks@sha256:3e88407e12f4ffd670655be130323215d92d635afd7d8df4380aecfa582bfb18
    - quay.io/modh/cuda-notebooks@sha256:6fadedc5a10f5a914bb7b27cd41bc644392e5757ceaf07d930db884112054265
    - quay.io/modh/cuda-notebooks@sha256:88d80821ff8c5d53526794261d519125d0763b621d824f8c3222127dab7b6cc8
    - quay.io/modh/cuda-notebooks@sha256:b6a91674b387a24caabeb8ad8a43cce0419eef89ec8ba5bb9090116f1ce63f6c
    - quay.io/modh/cuda-notebooks@sha256:f6cdc993b4d493ffaec876abb724ce44b3c6fc37560af974072b346e45ac1a3b
    - quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - quay.io/modh/odh-generic-data-science-notebook@sha256:40e0d2c21661ab4bf577082faaf3c06aac7b946a3b0be84c7568298c1bf2304f
    - quay.io/modh/odh-generic-data-science-notebook@sha256:76e6af79c601a323f75a58e7005de0beac66b8cccc3d2b67efb6d11d85f0cfa1
    - quay.io/modh/odh-generic-data-science-notebook@sha256:e2cab24ebe935d87f7596418772f5a97ce6a2e747ba0c1fd4cec08a728e99403
    - quay.io/modh/odh-habana-notebooks@sha256:0f6ae8f0b1ef11896336e7f8611e77ccdb992b49a7942bf27e6bc64d73205d05
    - quay.io/modh/odh-minimal-notebook-container@sha256:39068767eebdf3a127fe8857fbdaca0832cdfef69eed6ec3ff6ed1858029420f
    - quay.io/modh/odh-minimal-notebook-container@sha256:c1b6e34001d17b72847be387a073ce6394f992405376a63938a3128699a9d13b
    - quay.io/modh/odh-minimal-notebook-container@sha256:eec50e5518176d5a31da739596a7ddae032d73851f9107846a587442ebd10a82
    - quay.io/modh/odh-pytorch-notebook@sha256:30688e68a645db0000e450942d94a25dbae05576341c05eeb7074734fb286c8e
    - quay.io/modh/odh-pytorch-notebook@sha256:97b346197e6fc568c2eb52cb82e13a206277f27c21e299d1c211997f140f638b
    - quay.io/modh/odh-pytorch-notebook@sha256:b68e0192abf7d46c8c6876d0819b66c6a2d4a1e674f8893f8a71ffdcba96866c
    - quay.io/modh/odh-trustyai-notebook@sha256:8c5e653f6bc6a2050565cf92f397991fbec952dc05cdfea74b65b8fd3047c9d4
    - quay.io/modh/odh-trustyai-notebook@sha256:dc49e549521c16a6829950268e7efa969a7be8214f1e8f68ad2aa692fad2ec23
    - quay.io/modh/runtime-images@sha256:19387cc2b89de3dc49f96f50aa7b85c97fafac04f49611ce53a2940b5dc096b8
    - quay.io/modh/runtime-images@sha256:327bb23cf2b4cc1714728fda54edc2ac348d9a786668c72c406933363ab2e2f4
    - quay.io/modh/runtime-images@sha256:8c0f3d1e7a9baf5df5e21b67ffa22fc03d42d07c84b56b49547fd1f7607fc310
    - quay.io/modh/runtime-images@sha256:a3ee8b8eff99e9699fba1c1a51a9eedc4499caceeb4106e708da048ea0c30ef3
    - quay.io/modh/runtime-images@sha256:b721c133c43a50e52fe426c0e182da99f9b0c2724d682660eb4a54b1518ada55
    - quay.io/modh/runtime-images@sha256:d9cd06ab0f6ec763a11c602ed4482944700fc4a96c062066408686703e5327f5
    - quay.io/modh/runtime-images@sha256:e01b3041e73c8e16194cbca54d3dc12608ce555bebe410ea89da03ec372e3f15
    - quay.io/modh/runtime-images@sha256:f2d25913baf2b2ce1805095f09c4114da30d50b2b7c9e2c17733d6e88c410a87
    - quay.io/modh/openvino_model_server@sha256:5d04d405526ea4ce5b807d0cd199ccf7f71bab1228907c091e975efa770a4908
    - quay.io/modh/caikit-tgis-serving@sha256:444bca43c99bfc4b961c926f5f10c556488613912f5e333011e98b3407d76d00
    - quay.io/modh/text-generation-inference@sha256:e4d24fd401fd4eb89b49b4ab07e0c08389384d4a672b240e98a03ad7f9ef1c85
    - quay.io/modh/openvino_model_server@sha256:5d04d405526ea4ce5b807d0cd199ccf7f71bab1228907c091e975efa770a4908
    - quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94


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
    - name: quay.io/modh/codeserver@sha256:17e5bd18d6faaab72754936e4a89c2c596b2dfeb4be0aac6890b6f6145a13d6c
    - name: quay.io/modh/cuda-notebooks@sha256:00c53599f5085beedd0debb062652a1856b19921ccf59bd76134471d24c3fa7d
    - name: quay.io/modh/cuda-notebooks@sha256:3e88407e12f4ffd670655be130323215d92d635afd7d8df4380aecfa582bfb18
    - name: quay.io/modh/cuda-notebooks@sha256:6fadedc5a10f5a914bb7b27cd41bc644392e5757ceaf07d930db884112054265
    - name: quay.io/modh/cuda-notebooks@sha256:88d80821ff8c5d53526794261d519125d0763b621d824f8c3222127dab7b6cc8
    - name: quay.io/modh/cuda-notebooks@sha256:b6a91674b387a24caabeb8ad8a43cce0419eef89ec8ba5bb9090116f1ce63f6c
    - name: quay.io/modh/cuda-notebooks@sha256:f6cdc993b4d493ffaec876abb724ce44b3c6fc37560af974072b346e45ac1a3b
    - name: quay.io/modh/odh-anaconda-notebook@sha256:380c07bf79f5ec7d22441cde276c50b5eb2a459485cde05087837639a566ae3d
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:40e0d2c21661ab4bf577082faaf3c06aac7b946a3b0be84c7568298c1bf2304f
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:76e6af79c601a323f75a58e7005de0beac66b8cccc3d2b67efb6d11d85f0cfa1
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:e2cab24ebe935d87f7596418772f5a97ce6a2e747ba0c1fd4cec08a728e99403
    - name: quay.io/modh/odh-habana-notebooks@sha256:0f6ae8f0b1ef11896336e7f8611e77ccdb992b49a7942bf27e6bc64d73205d05
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:39068767eebdf3a127fe8857fbdaca0832cdfef69eed6ec3ff6ed1858029420f
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:c1b6e34001d17b72847be387a073ce6394f992405376a63938a3128699a9d13b
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:eec50e5518176d5a31da739596a7ddae032d73851f9107846a587442ebd10a82
    - name: quay.io/modh/odh-pytorch-notebook@sha256:30688e68a645db0000e450942d94a25dbae05576341c05eeb7074734fb286c8e
    - name: quay.io/modh/odh-pytorch-notebook@sha256:97b346197e6fc568c2eb52cb82e13a206277f27c21e299d1c211997f140f638b
    - name: quay.io/modh/odh-pytorch-notebook@sha256:b68e0192abf7d46c8c6876d0819b66c6a2d4a1e674f8893f8a71ffdcba96866c
    - name: quay.io/modh/odh-trustyai-notebook@sha256:8c5e653f6bc6a2050565cf92f397991fbec952dc05cdfea74b65b8fd3047c9d4
    - name: quay.io/modh/odh-trustyai-notebook@sha256:dc49e549521c16a6829950268e7efa969a7be8214f1e8f68ad2aa692fad2ec23
    - name: quay.io/modh/runtime-images@sha256:19387cc2b89de3dc49f96f50aa7b85c97fafac04f49611ce53a2940b5dc096b8
    - name: quay.io/modh/runtime-images@sha256:327bb23cf2b4cc1714728fda54edc2ac348d9a786668c72c406933363ab2e2f4
    - name: quay.io/modh/runtime-images@sha256:8c0f3d1e7a9baf5df5e21b67ffa22fc03d42d07c84b56b49547fd1f7607fc310
    - name: quay.io/modh/runtime-images@sha256:a3ee8b8eff99e9699fba1c1a51a9eedc4499caceeb4106e708da048ea0c30ef3
    - name: quay.io/modh/runtime-images@sha256:b721c133c43a50e52fe426c0e182da99f9b0c2724d682660eb4a54b1518ada55
    - name: quay.io/modh/runtime-images@sha256:d9cd06ab0f6ec763a11c602ed4482944700fc4a96c062066408686703e5327f5
    - name: quay.io/modh/runtime-images@sha256:e01b3041e73c8e16194cbca54d3dc12608ce555bebe410ea89da03ec372e3f15
    - name: quay.io/modh/runtime-images@sha256:f2d25913baf2b2ce1805095f09c4114da30d50b2b7c9e2c17733d6e88c410a87
    - name: quay.io/modh/openvino_model_server@sha256:5d04d405526ea4ce5b807d0cd199ccf7f71bab1228907c091e975efa770a4908
    - name: quay.io/modh/caikit-tgis-serving@sha256:444bca43c99bfc4b961c926f5f10c556488613912f5e333011e98b3407d76d00
    - name: quay.io/modh/text-generation-inference@sha256:e4d24fd401fd4eb89b49b4ab07e0c08389384d4a672b240e98a03ad7f9ef1c85
    - name: quay.io/modh/openvino_model_server@sha256:5d04d405526ea4ce5b807d0cd199ccf7f71bab1228907c091e975efa770a4908
    - name: quay.io/modh/must-gather@sha256:c2d780156a0e7cec975c9c150bee00b1facb8f6213e7b98a7a489448d76dfd94

```

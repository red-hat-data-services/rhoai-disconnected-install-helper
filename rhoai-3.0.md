# Additional images:
    - quay.io/jtanner/kube-auth-proxy:latest@sha256:434580fd42d73727d62566ff6d8336219a31b322798b48096ed167daaec42f07



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
        minVersion: 3.0.0
        maxVersion: 3.0.0
  additionalImages:   
    - name: quay.io/jtanner/kube-auth-proxy:latest@sha256:434580fd42d73727d62566ff6d8336219a31b322798b48096ed167daaec42f07




```

# Additional images:




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
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.20
    packages:
    - name: rhods-operator
      channels:
      - name: fast
        minVersion: 3.5-ea.2.0
        maxVersion: 3.5-ea.2.0
  additionalImages:
    - name: registry.redhat.io/openshift4/ose-kube-rbac-proxy-rhel9@sha256:11828cdb31cd9c1e15bc9e31c7e4669daf71c84c028cad2df5dbab68150da273





```

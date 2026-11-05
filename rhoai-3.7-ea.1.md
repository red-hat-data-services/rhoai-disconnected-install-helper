# Additional images:




# Unsupported Images:
These images are no longer officially supported but are still provided for convenience.
(They may be useful for users who wish to import older resources or maintain compatibility with previous setups.)

# ImageSetConfiguration example (oc-mirror v2):
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
archiveSize: 4
mirror:
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.20
    packages:
    - name: rhods-operator
      defaultChannel: fast
      channels:
      - name: fast
        minVersion: 3.7-ea.1.0
        maxVersion: 3.7-ea.1.0
  additionalImages:   





```

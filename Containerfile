# Use Red Hat Universal Base Image Minimal
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

# Install required tools
RUN microdnf install -y bash jq gzip skopeo wget git findutils && \
    microdnf clean all && \
    rm -rf /var/cache/yum

# Install OpenShift CLI
RUN curl -Lo oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz && \
    tar -xf oc.tar.gz -C /usr/local/bin/ && \
    rm -f oc.tar.gz

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/download/v4.9.6/yq_linux_amd64 -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

# Set work directory
WORKDIR /app

# Copy the script into the image
COPY rhods-disconnected-helper.sh /app/

# Make the script executable
RUN chmod +x /app/rhods-disconnected-helper.sh

# Set the entrypoint with mandatory arguments
ENTRYPOINT [ "/app/rhods-disconnected-helper.sh" ]
FROM openshift/ose-base:ubi8

ENV SUMMARY="RHEL8 based Go builder image for OpenShift ART" \
    container=oci \
    GOFLAGS='-mod=vendor' \
    GOPATH=/go \
    VERSION="1.14"

LABEL summary="$SUMMARY" \
      description="$SUMMARY" \
      io.k8s.description="$SUMMARY" \
      io.k8s.display-name="Go Builder $VERSION" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
      version="$VERSION"

RUN yum install -y --setopt=tsflags=nodocs \
    bc diffutils file findutils gpgme git hostname lsof make rsync socat tar tree util-linux wget which zip \
    "go-toolset-$VERSION.*" goversioninfo openssl openssl-devel systemd-devel gpgme-devel libassuan-devel && \
    mkdir -p /go/src && \
    yum clean all -y
    
ADD cross.tar.gz .
RUN [ $(go env GOARCH) != "amd64" ] || (\
    # only install cross-compiler dependencies on amd64
    yum install -y --setopt=tsflags=nodocs \
    # Required packages for mac cross-compilation
    patch xz llvm-toolset libtool cmake3 gcc-c++ libxml2-devel \
    # Required packages for windows cross-compilation
    glibc mingw64-gcc && \
    # compile macos cross-compilers
    export TP_OSXCROSS_DEV=$(pwd)/cross/deps && \
    pushd cross/osxcross && \
    UNATTENDED=yes ./build.sh && \
    popd && \
    cp -avr cross/osxcross/target/bin/* /usr/local/bin/ && \
    yum clean all -y)
RUN rm -rf cross
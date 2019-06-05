FROM lambci/lambda-base

RUN find /usr ! -type d | sort > fs.txt && \
  ( yum check || yum reinstall -y ImageMagick ) && \
  yum reinstall -y openssl openssh-clients fipscheck-lib && \
  bash -c 'comm -13 fs.txt <(find /usr ! -type d | sort)' | \
  grep -v ^/usr/share | \
  tar -c -T - | \
  tar -x --strip-components=1 -C /opt && \
  mv /opt/lib64 /opt/lib


FROM lambci/lambda-base:build

COPY --from=0 /opt /opt

RUN yum install -y --releasever=latest yum-utils rpm-build && \
  yumdownloader --source openssh && \
  yum-builddep -y openssh && \
  rpm -ivh *.rpm

RUN cd /usr/src/rpm/SPECS && \
  rpmbuild -bi openssh.spec && \
  cp /usr/src/rpm/BUILDROOT/openssh*/usr/bin/ssh /opt/bin/

ARG GIT_VERSION

ENV NO_GETTEXT=1 NO_PERL=1 NO_TCLTK=1 NO_PYTHON=1 INSTALL_SYMLINKS=1

RUN curl https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz | tar -xJ && \
  cd git-${GIT_VERSION} && \
  make prefix=/opt && \
  make prefix=/opt strip && \
  make prefix=/opt install && \
  rm -rf /opt/share/git-core/templates/*

RUN cd /opt && \
  find . ! -perm -o=r -exec chmod +400 {} \; && \
  zip -yr /tmp/git-${GIT_VERSION}.zip ./*

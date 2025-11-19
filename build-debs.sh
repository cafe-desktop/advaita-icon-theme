#!/bin/bash

set -e
set -v
set -x

# sample:
# ./build-debs https://github.com/cafe-desktop/debian-packages master cafe-sensors-applet
# or just ./build-debs for current repo with master branch

if [ $# -eq 0 ]
then
  giturl=https://github.com/${OWNER_NAME}/debian-packages
  gitbranch=master
  gitrepo=${REPO_NAME}
else
  giturl=$1
  gitbranch=$2
  gitrepo=$3
fi

#expect required for unbuffer
aptitude install -y devscripts dh-make dh-exec gdebi lintian expect
cd ${START_DIR}
mkdir -p html-report
git clone --depth 1 ${giturl}.git -b ${gitbranch} tmp-debs
cp -dpR ./tmp-debs/${gitrepo}/debian .
tar cfJv ../debian.tar.xz debian
mk-build-deps debian/control
gdebi --n *.deb
rm *deps*
dpkg-buildpackage -b -rfakeroot -us -uc
aptitude purge -y `sed -n 's/^Source: *//p' debian/control`-build-deps
cd ..
tar cfJv deb_packages.tar.xz *deb *buildinfo *changes
if dpkg -i *.deb; then
  echo
else
  aptitude -f -y install
  dpkg -i *.deb
fi
unbuffer lintian &> /dev/null #check if unbuffer and lintian are installed
unbuffer lintian -i -EIL+pedantic *.changes > lintianlog || echo lintian error!
cat lintianlog | grep -E '^(E:|W:|I:|X:|P:)' || echo lintian is OK!
mv *deb *buildinfo *changes debian.tar.xz deb_packages.tar.xz .${START_DIR}/html-report

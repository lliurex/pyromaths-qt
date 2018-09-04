#!/bin/bash
DIR=$(cd `dirname $0` && pwd)
PYROPATH=$(cd `dirname $0` && cd .. && pwd)

# Install build dependencies (if needed)
if [ ! -f /usr/bin/debuild ];
then
    sudo apt-get install devscripts equivs python-setuptools dh-python
fi
if [ ! -f /usr/bin/rpm ];
then
    sudo apt-get install rpm
fi
if [ ! -f /usr/lib/python2.7/dist-packages/sphinxarg/ext.py ];
then
    sudo apt install python-sphinx-argparse
fi

# Update pyromaths-qt version
VERSION=$(grep VERSION $PYROPATH/pyromaths/qt/version.py | sed "s/.*= '//")
VERSION=${VERSION%?}
echo "Version de Pyromaths-QT ? (${VERSION})"
read touche
case "$touche" in
  "" )
  VERSIONQT="$VERSION"
  ;;
  * )
  VERSIONQT="$touche"
  ;;
esac
if [ "$VERSIONQT" == "$VERSION" ] 
then
    NEW=false
    echo "On ne compile que la version Windows et on crée les liens pour le site"
else
    echo "On compile une nouvelle version de Pyromaths-QT"
    sed -i "s/VERSION ?= .*/VERSION ?= ${VERSIONQT}/" ${PYROPATH}/Makefile
    NEW=true
fi

# Update pyromaths version
VERSION=`date +%y.%m`
echo "Version de Pyromaths ? (${VERSION})"
read touche
case "$touche" in
  "" )
  ;;
  * )
  VERSION="$touche"
  ;;
esac
echo "*** Update pyromaths version..."
sed -i "0,/^version=.*$/s//version=${VERSION}/" ${PYROPATH}/data/windows/installer.cfg
sed -i "s/pyromaths==.*/pyromaths==${VERSION}/" ${PYROPATH}/data/windows/installer.cfg 
cat  ${PYROPATH}/data/windows/installer.cfg 
# Prepare Changelog
if [ "$NEW" == true ]
then
    cd $PYROPATH
    head -20 NEWS
    dch -v ${VERSIONQT}-1
    dch -r

    # Clean-up and create packages
    make clean
    make all
    make repo
else
    make clean
    make src
    make wheel
fi

echo "*** Create Windows binary..."
echo "Hit 'enter' when Windows package is ready."
read touche

if [ "$NEW" == true ]
then
    echo "*** Tag git develop ***"
    echo "Do you want to commit and tag the git develop branch (o/N)?"
    read touche
    case "$touche" in
      [oO] )
      git commit -am 'Pyromaths-qt Release'
      git tag -u B39EE5B6 version-${VERSIONQT} -m "Pyromaths-qt ${VERSIONQT}"
      #git push --tags:
      ;;
    esac
fi

echo "*** Update pyromaths web-site links..."
cat > ${PYROPATH}/pyrosite.txt << EOF
:title: Version ${VERSION}
:slug: version-$(echo ${VERSION} | sed 's/\./-/g')
:date: $(date +"%Y-%m-%d %H:%M")
:category: telecharger
:description: Liens vers la version ${VERSION}

* |debian| \`Pyromaths pour Linux - deb <https://www.pyromaths.org/downloads/pyromaths_${VERSION}-1_all.deb>\`_ et \`Pyromaths-qt pour Linux - deb <https://www.pyromaths.org/downloads/pyromaths-qt_${VERSIONQT}-1_all.deb>\`_
* |redhat| \`Pyromaths pour Linux - rpm <https://www.pyromaths.org/downloads/pyromaths-${VERSION}-1.noarch.rpm>\`_ et \`Pyromaths-qt pour Linux - rpm <https://www.pyromaths.org/downloads/pyromaths-qt-${VERSIONQT}-1.noarch.rpm>\`_
* |macos| Bientôt disponibe
* |windows| \`Pyromaths pour Windows <https://www.pyromaths.org/downloads/Pyromaths-QT_${VERSION}.exe>\`_
* |sources| \`Sources de Pyromaths <https://pypi.org/project/pyromaths/>\`_

.. |debian| image:: images/debian.png
    :alt: Debian Linux
.. |redhat| image:: images/redhat.png
    :alt: RedHat Linux
.. |macos| image:: images/macosx.png
    :alt: Mac OS X
.. |windows| image:: images/winvista.png
    :alt: Windows
.. |sources| image:: images/source.png
    :alt: Sources

Nouveautés de cette version :
=============================

EOF

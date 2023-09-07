# Pyromaths Makefile.
#
# See 'make help' for available targets and usage details.

### CONFIG
#
# Pyromaths-qt version
VERSION ?= 21.8
# Pyromaths version
VERSION_CL ?= 21.8.2
# Archive format(s) produced by 'make src' (bztar,gztar,zip...)
FORMATS ?= bztar,zip,gztar
# Verbosity and logging
#OUT     ?= > /dev/null       # uncomment: quieter output
OUT     ?= >> /tmp/log            # uncomment: log output to file

### ENVIRONMENT VARIABLES
#
# Path
PYRO    := $(PWD)
DIST    := $(PYRO)/dist
BUILD   := $(PYRO)/build
ARCHIVE := $(PYRO)/..
# Target-specific build dir (if needed)
BUILDIR  = $(BUILD)/$@
# Mac app folder
APP     := $(DIST)/Pyromaths.app/Contents
# Project files
FILES   := AUTHORS COPYING NEWS pyromaths README setup.py MANIFEST.in

### SHORTCUTS & COMPATIBILITY
#
ifeq ($(OS),Windows_NT)
	# Windows
	PYTHON ?= c:/Python3/python.exe
else
	# Unix
	PYTHON ?= python3
	ifeq ($(shell uname -s),Darwin)
		# Mac/BSD
		sed-i := sed -i ''
	else
		# GNU
		sed-i := sed -i
	endif
endif
$(info $$PYTHON is [${PYTHON}])
setup := $(PYTHON) setup.py

### MACROS
#
# Remove egg-info dir and target build dir, clean-up sources.
clean = rm -rf *.egg-info && rm -rf $(BUILDIR) &&\
        find . -name '*~' | xargs rm -f && find . -iname '*.pyc' | xargs rm -f


# src must be after rpm, otherwise rpm produces a .tar.gz file that replaces the
# .tar.gz source file (should $$FORMATS include gztar).
all: wheel rpm deb src

help:
	#
	# Build pyromaths packages in several formats.
	#
	# Usage (Unix):
	#	$$ make src          # Make full-source archive(s)
	#	$$ make wheel        # Make python wheel
	#	$$ make rpm          # Make RPM package
	#	$$ make deb          # Make DEB package
	#	$$ make [all]        # Make all previous archives/packages
	#
	# Usage (Mac):
	#	$$ make app          # Make standalone application
	#
	# Usage (Windows):
	#	$$ make exe          # Make standalone executable (experimental)
	#
	# And also:
	#	$$ make version      # Apply target $$VERSION [$(VERSION)] to sources
	# 	$$ make clean        # Clean-up build/dist folders and source tree
	#	$$ make repo         # Make debian repository
	#
	# Notes:
	#	- Notice the source achive $$FORMATS produced [$(FORMATS)].
	#	- Mangle with $$OUT to make it quieter/verbose/log to output file.

clean:
	# Clean
	rm -r $(BUILD)/* || mkdir -p $(BUILD)
	rm -r $(DIST)/*  || mkdir -p $(DIST)
	rmdir $(BUILD)
	rmdir $(DIST)
	rm -r $(PYRO)/extra_wheel
	$(clean)

version:
	# Apply target version ($(VERSION)) to sources
	$(sed-i) "s/VERSION\s*=\s*'.*'/VERSION = '$(VERSION)'/" pyromaths/qt/version.py
	$(sed-i) "s/VERSION_CL\s*=\s*'.*'/VERSION_CL = '$(VERSION_CL)'/" pyromaths/qt/version.py
	$(sed-i) "s/pyromaths_qt==.*/pyromaths_qt==$(VERSION)/" data/windows/installer.cfg 
	$(sed-i) "s/pyromaths==.*/pyromaths==$(VERSION_CL)/" data/windows/installer.cfg 
	$(sed-i) "0,/version=.*/s//version=$(VERSION_CL)/" data/windows/installer.cfg 
	$(sed-i) "s/Pyromaths-QT_.*\.exe /Pyromaths-QT_$(VERSION_CL).exe /" data/windows/compile_pyromaths.bat 
	$(sed-i) "s/pyromaths-qt-[0-9\.]*\.zip/pyromaths-qt-$(VERSION).zip/" data/windows/compile_pyromaths.bat 
	$(sed-i) "s/pyromaths-qt-[0-9\.]*\r/pyromaths-qt-$(VERSION)/" data/windows/compile_pyromaths.bat 

src: version
	# Make full-source archive(s) (formats=$(FORMATS))
	$(clean)
	$(setup) sdist --formats=$(FORMATS) -d $(DIST) $(OUT)

pypi: wheel src
	# Publish to Pypi
	@echo "################################################################################"
	@echo "# To upload to Pypi, run:"
	@echo twine upload -s dist/pyromaths_qt-$(VERSION)-py3-none-any.whl dist/pyromaths-qt-$(VERSION).tar.gz

wheel: version
	# Make python wheel
	$(clean)
	$(setup) bdist_wheel -d $(DIST) $(OUT)

rpm: version
	# Make RPM package
	$(clean)
	$(setup) bdist --formats=rpm -b $(BUILD) -d $(DIST) $(OUT)
	rm -f $(DIST)/pyromaths-qt-$(VERSION).tar.gz

min: version
	# Make minimalist .tar.bz source archive in $(BUILD)
	$(clean)
	$(setup) sdist --formats=bztar -d $(BUILD) $(OUT)

.ONESHELL:
deb: min
	# Make DEB archive
	$(clean)
	set -e
	(
		cd $(BUILD)
		tar -xjf pyromaths-qt-$(VERSION).tar.bz2
		mv pyromaths-qt-$(VERSION) $(BUILDIR)
		mv pyromaths-qt-$(VERSION).tar.bz2 pyromaths-qt_$(VERSION).orig.tar.bz2
	)
	cp -r debian $(BUILDIR)
	(
		cd $(BUILDIR)
		debuild -i -D -tc -k'Jérôme Ortais (Développeur du logiciel Pyromaths) <jerome.ortais@pyromaths.org>' -b $(OUT) 
		#debuild -i -D -tc -kB39EE5B6 $(OUT)
	)
	mkdir -p $(DIST)
	mv $(BUILD)/pyromaths-qt_$(VERSION)-*_all.deb $(DIST)

repo: min
	# update apt repository
	$(clean)
	set -e
	(
		cd $(BUILD) && tar -xjf pyromaths-qt-$(VERSION).tar.bz2              &&\
	    mv pyromaths-qt-$(VERSION) $(BUILDIR)                            &&\
	    mv pyromaths-qt-$(VERSION).tar.bz2 pyromaths-qt_$(VERSION).orig.tar.bz2
	)
	cp -r debian $(BUILDIR)
	(
		cd $(BUILDIR) 
		debuild -S -sa -k'Jérôme Ortais (Développeur du logiciel Pyromaths) <jerome.ortais@pyromaths.org>' $(OUT) 
	)
	(
		cd $(BUILD)
		dput -l -f ppa:jerome-ortais/ppa $(BUILD)/pyromaths-qt_$(VERSION)-1_source.changes
	)

data/%.qm: data/%.ts
	# Translate new/updated language files
	lrelease $< -qm $@

app: 
	# ..Remove previous build
	rm -rf $(BUILD) $(DIST) 
	# Make standalone Mac application
	$(setup) py2app -O2 -b $(BUILD) -d $(DIST) $(OUT)
	# ..Clean-up unnecessary files/folders
	rm -f $(APP)/PkgInfo
	cd $(APP)/Resources &&\
	    rm -rf include zlib.cpython-3* lib/python3.*/config-3.* lib/python3.*/site.py*
	cd $(APP)/Resources/lib/python3.7/PyQt5/Qt/lib &&\
	    rm -rf QtBluetooth.framework QtConcurrent.framework QtDBus.framework \
	    QtHelp.framework QtLocation.framework QtMacExtras.framework QtMultimedia.framework \
	    QtMultimediaWidgets.framework QtNetwork.framework QtNetworkAuth.framework \
	    QtNfc.framework QtOpenGL.framework QtPositioning.framework QtQml.framework \
	    QtQuick.framework QtQuickControls2.framework QtQuickParticles.framework \
	    QtQuickTemplates2.framework QtSql.framework QtSvg.framework QtTest.framework \
	    QtWebEngineWidgets.framework QtWebSockets.framework QtXml.framework \
	    QtXmlPatterns.framework QtQuickTest.framework QtQuickWidgets.framework \
	    QtSensors.framework QtSerialPort.framework QtWebChannel.framework \
	    QtWebEngine.framework QtWebEngineCore.framework
	cd $(APP)/Resources/lib/python3.7/PyQt5/ &&\
		rm -rf Qt.so QtSerialPort.so QtBluetooth.so QtSql.so QtDBus.so	QtSvg.so \
		QtDesigner.so QtTest.so QtHelp.so QtWebChannel.so QtLocation.so	QtWebEngine.so \
		QtMacExtras.so QtWebEngineCore.so QtMultimedia.so QtWebEngineWidgets.so \
		QtMultimediaWidgets.so QtWebSockets.so QtNetwork.so	QtXml.so QtNetworkAuth.so \
		QtXmlPatterns.so QtNfc.so _QOpenGLFunctions_2_0.so QtOpenGL.so _QOpenGLFunctions_2_1.s \
		QtPositioning.so _QOpenGLFunctions_4_1_Core.so QtPrintSupport.so pylupdate.so QtQml.so \
		pylupdate_main.py QtQuick.so pyrcc.so QtQuickWidgets.so pyrcc_main.py QtSensors.so uic
	cd $(APP)/Resources/lib/python3.7/PyQt5/Qt/plugins &&\
		rm -rf audio geoservices platformthemes \
		sceneparsers webview bearer iconengines playlistformats sensorgestures \
		gamepads imageformats position sensors generic mediaservice printsupport sqldrivers \
		geometryloaders	renderplugins texttospeech platforms/libqminimal.dylib \
		platforms/libqoffscreen.dylib platforms/libqwebgl.dylib
	cd $(APP)/Resources/lib/python3.7/PyQt5/Qt && rm -rf qml translations 
	cd $(APP)/Resources/lib/python3.7/PyQt5/Qt/plugins &&\
	cd $(APP)/Frameworks                                     &&\
	    rm -rf libcrypto.1.1.dylib libssl.1.1.dylib
	cd $(APP)/Resources/lib/python3.7/pyromaths                                    &&\
	    rm -rf qt
	cd $(APP)/Resources &&\
	    find * -name '__pycache__' | xargs rm -rf
	# Copy missing files
	cd /Library/Frameworks/Python.framework/Versions/3.*/lib/python3.*/site-packages/pyromaths/ &&\
	    cp -r classes cli data directories.py ex outils $(APP)/Resources/lib/python3.*/pyromaths/
	# ..Remove all architectures but x86_64..."
	ditto --rsrc --arch x86_64 --hfsCompression $(DIST)/Pyromaths.app $(DIST)/Pyromaths-x86_64.app

.ONESHELL:
exe: version src wheel
	# Prepare for standalone Windows executable
	cd $(PYRO)
	mkdir -p extra_wheel
	cp dist/pyromaths_qt-$(VERSION)-py3-none-any.whl extra_wheel
	cp ../pyromaths/dist/pyromaths-$(VERSION_CL)-py3-none-any.whl extra_wheel
	#python3 -m nsist installer.cfg
	#mv $(PYRO)/data/windows/build/nsis/Pyromaths-QT_*.exe $(DIST)

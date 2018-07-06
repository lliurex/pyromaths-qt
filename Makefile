# Pyromaths Makefile.
#
# See 'make help' for available targets and usage details.

### CONFIG
#
# Pyromaths version
VERSION ?= 18.6.2
# Archive format(s) produced by 'make src' (bztar,gztar,zip...)
FORMATS ?= bztar,zip
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
FILES   := AUTHORS COPYING NEWS pyromaths README setup.py MANIFEST.in src data

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
	$(clean)

version:
	# Apply target version ($(VERSION)) to sources
	$(sed-i) "s/VERSION\s*=\s*'.*'/VERSION = '$(VERSION)'/" pyromaths/qt/version.py

src: version
	# Make full-source archive(s) (formats=$(FORMATS))
	$(clean)
	$(setup) sdist --formats=$(FORMATS) -d $(DIST) $(OUT)

wheel: version
	# Make python wheel
	$(clean)
	$(setup) bdist_wheel -d $(DIST) $(OUT)

rpm: version
	# Make RPM package
	$(clean)
	$(setup) bdist --formats=rpm -b $(BUILD) -d $(DIST) $(OUT)
	rm -f $(DIST)/pyromaths-$(VERSION).tar.gz

min: version
	# Make minimalist .tar.bz source archive in $(BUILD)
	$(clean)
	$(setup) sdist --formats=bztar -d $(BUILD) $(OUT)

deb: min
	# Make DEB archive
	$(clean)
	cd $(BUILD) && tar -xjf pyromaths-$(VERSION).tar.bz2              &&\
	    mv pyromaths-$(VERSION) $(BUILDIR)                            &&\
	    mv pyromaths-$(VERSION).tar.bz2 pyromaths_$(VERSION).orig.tar.bz2
	cp -r debian $(BUILDIR)
	cd $(BUILDIR) && debuild -i -D -tc -kB39EE5B6 $(OUT) || exit 0
	mkdir -p $(DIST)
	mv $(BUILD)/pyromaths_$(VERSION)-*_all.deb $(DIST)

repo: min
	# update apt repository
	$(clean)
	cd $(BUILD) && tar -xjf pyromaths-$(VERSION).tar.bz2              &&\
	    mv pyromaths-$(VERSION) $(BUILDIR)                            &&\
	    mv pyromaths-$(VERSION).tar.bz2 pyromaths_$(VERSION).orig.tar.bz2
	cp -r debian $(BUILDIR)
	cd $(BUILDIR) && debuild -i -tc -kB39EE5B6 -S $(OUT)
	cd $(BUILD)
	#dput -l $(BUILD)/pyromaths_$(VERSION)-1_amd64.changes
	dput -l -f ppa:jerome-ortais/ppa $(BUILD)/pyromaths_$(VERSION)-1_source.changes

data/%.qm: data/%.ts
	# Translate new/updated language files
	lrelease $< -qm $@

app: version data/qtmac_fr.qm
	# ..Remove previous build
	rm -rf $(BUILD) $(DIST)
	# Make standalone Mac application
	$(setup) py2app -O2 -b $(BUILD) -d $(DIST) $(OUT)
	# ..Clean-up unnecessary files/folders
	rm -f $(APP)/PkgInfo
	cd $(APP)/Resources && rm -rf site.pyc include lib/python2.*/config lib/python2.*/site.pyc
	cd $(APP)/Frameworks                                     &&\
	    rm -rf *.framework/Contents *.framework/Versions/4.0   \
	           *.framework/Versions/Current *.framework/*.prl  \
	           QtCore.framework/QtCore QtGui.framework/QtGui
	cd $(APP)/Frameworks/Python.framework/Versions/2.*       &&\
	    rm -rf include lib Resources
	rm -rf $(APP)/Resources/lib/python2.7/pyromaths.ex/examples
	find $(APP)/Resources/lib/python2.7/pyromaths.ex \( -name '*.pyc' \) -delete
	rm -rf $(APP)/Frameworks/pyromaths
	# ..Remove all architectures but x86_64..."
	ditto --rsrc --arch x86_64 --hfsCompression $(DIST)/Pyromaths.app $(DIST)/Pyromaths-x86_64.app

exe:
	# Make standalone Windows executable
	# ..Remove previous builds
	cp $(PYRO)/data/windows/installer.cfg $(PYRO)
	cp $(PYRO)/data/windows/nsi_template.nsi $(PYRO)
	pynsist installer.cfg
	mkdir -p $(DIST)
	mv $(BUILD)/nsis/Pyromaths_$(VERSION).exe $(DIST)
	rm $(PYRO)/installer.cfg 
	rm $(PYRO)/nsi_template.nsi

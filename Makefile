BASEDIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
BUILDDIR:=$(BASEDIR)/build
PACKAGEDIR:=$(BASEDIR)/packages
REPOS:=bootloader coreutils generated kernel kinit liblua devtab
EXECVARS:=TARGET="$(PACKAGEDIR)/$$f/build" BASE="$(BASEDIR)" SRC="$(PACKAGEDIR)/$$f" PACKAGEDIR="$(PACKAGEDIR)"

all: clean setup build-all install


setup:
	@if test -d "$(BUILDDIR)" ; then \
		rm -rf $(BUILDDIR) ; \
	fi
	@mkdir -p $(BUILDDIR)

clean:
	@echo "[RM] /build"
	@rm -rf $(BUILDDIR)
	@for f in $(REPOS) ; do \
		echo "[CLEAN] $$f" ; \
		rm -rf "$(PACKAGEDIR)/$$f/build" ; \
	done

install:
	@for f in $(REPOS) ; do \
		echo "[INSTALL] $$f" ; \
		cp -a "$(PACKAGEDIR)/$$f/build/." $(BUILDDIR) ; \
	done

build-all:
	@for f in $(REPOS) ; do \
		if test -f "$(PACKAGEDIR)/$$f/Makefile" ; then \
			echo "[BUILD] $$f" ; \
			make --no-print-directory -C "$(PACKAGEDIR)/$$f" build $(EXECVARS) ; \
		else \
			echo "[ERR] $$f does not have a makefile" ; \
			exit 1 ; \
		fi ; \
	done

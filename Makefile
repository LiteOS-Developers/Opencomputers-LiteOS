BASEDIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
BUILDDIR:=$(BASEDIR)/build
REPOS:=bootloader coreutils generated kernel kinit liblua
EXECVARS:=TARGET="$(BASEDIR)/$$f/build" BASE="$(BASEDIR)" SRC="$(BASEDIR)/$$f"

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
		rm -rf "$(BASEDIR)/$$f/build" ; \
	done

install:
	@for f in $(REPOS) ; do \
		echo "[INSTALL] $$f" ; \
		cp -a "$(BASEDIR)/$$f/build/." $(BUILDDIR) ; \
	done

build-all:
	@for f in $(REPOS) ; do \
		if test -f "$(BASEDIR)/$$f/Makefile" ; then \
			echo "[BUILD] $$f" ; \
			make --no-print-directory -C "$(BASEDIR)/$$f" build $(EXECVARS) ; \
		else \
			echo "[ERR] $$f does not have a makefile" ; \
			exit 1 ; \
		fi ; \
	done

#!/bin/make
#
# NetSurf Source makefile for libraries and browser

# Component settings
COMPONENT := netsurf-all
COMPONENT_VERSION := 3.1

.PHONY: build install clean release-checkout dist

export TARGET ?= gtk
export PKG_CONFIG_PATH = $(TMP_PREFIX)/lib/pkgconfig
TMP_PREFIX := $(CURDIR)/inst-$(TARGET)

NETSURF_TARG := netsurf

# nsgenbind host tool
NSGENBIND_TARG := nsgenbind

NSLIB_ALL_TARG :=  buildsystem libwapcaplet libparserutils libcss libhubbub libdom libnsbmp libnsgif librosprite libsvgtiny

NSLIB_FB_TARG := libnsfb

NSLIB_RO_TARG := librufl libpencil

# only build what we reuire for the target
ifeq ($(TARGET),riscos)
  NSLIB_TARG := $(NSLIB_ALL_TARG) $(NSLIB_RO_TARG)
else
  ifeq ($(TARGET),framebuffer)
    NSLIB_TARG := $(NSLIB_ALL_TARG) $(NSLIB_FB_TARG)
  else
    NSLIB_TARG := $(NSLIB_ALL_TARG)
  endif
endif

# clean macro for each sub target
define do_clean
	$(MAKE) distclean --directory=$1 TARGET=$(TARGET)

endef

# prefixed install macro for each sub target
define do_prefix_install
	$(MAKE) install --directory=$1 TARGET=$(TARGET) PREFIX=$(TMP_PREFIX) DESTDIR=

endef

build: $(TMP_PREFIX)/build-stamp

$(TMP_PREFIX)/build-stamp:
	mkdir -p $(TMP_PREFIX)/include
	mkdir -p $(TMP_PREFIX)/lib
	mkdir -p $(TMP_PREFIX)/bin
	$(foreach L,$(NSLIB_TARG),$(call do_prefix_install,$(L)))
	$(MAKE) install --directory=$(NSGENBIND_TARG) PREFIX=$(TMP_PREFIX) TARGET=$(shell uname -s)
	$(MAKE) --directory=$(NETSURF_TARG) PREFIX=$(PREFIX) TARGET=$(TARGET)
	touch $@

package: $(TMP_PREFIX)/build-stamp
	$(MAKE) --directory=$(NETSURF_TARG) PREFIX=$(PREFIX) TARGET=$(TARGET) package

install: $(TMP_PREFIX)/build-stamp
	$(MAKE) install --directory=$(NETSURF_TARG) TARGET=$(TARGET) PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)

clean:
	$(RM) -r $(TMP_PREFIX)
	$(foreach L,$(NSLIB_TARG),$(call do_clean,$(L)))
	$(MAKE) clean --directory=$(NSGENBIND_TARG) TARGET=$(TARGET)
	$(MAKE) clean --directory=$(NETSURF_TARG) TARGET=$(TARGET)

release-checkout: $(NSLIB_TARG) $(NETSURF_TARG) $(NSGENBIND_TARG) $(NSLIB_RO_TARG)
	for x in $^; do cd $$x; (git checkout origin/HEAD && git checkout $$(git describe --abbrev=0 --match="release/*" )); cd ..; done

dist:
	$(eval GIT_TAG := $(shell git describe --abbrev=0 --match "release/*"))
	$(eval GIT_VER := $(shell x="$(GIT_TAG)"; echo "$${x#release/}"))
	$(if $(subst $(GIT_VER),,$(COMPONENT_VERSION)), $(error Component Version "$(COMPONENT_VERSION)" and GIT tag version "$(GIT_VER)" do not match))
	$(eval DIST_FILE := $(COMPONENT)-${GIT_VER})
	$(Q)git-archive-all --force-submodules --prefix=$(DIST_FILE)/ $(DIST_FILE).tgz
	$(Q)mv $(DIST_FILE).tgz $(DIST_FILE).tar.gz

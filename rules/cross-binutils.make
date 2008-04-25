# -*-makefile-*-
# $Id$
#
# Copyright (C) 2006 by Robert Schwebel
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
CROSS_PACKAGES-$(PTXCONF_CROSS_BINUTILS) += cross-binutils

#
# Paths and names
#
CROSS_BINUTILS_VERSION	:= $(call remove_quotes,$(PTXCONF_CROSS_BINUTILS_VERSION))
CROSS_BINUTILS		:= binutils-$(CROSS_BINUTILS_VERSION)
CROSS_BINUTILS_SUFFIX	:= tar.bz2
CROSS_BINUTILS_URL	:= $(PTXCONF_SETUP_GNUMIRROR)/binutils/$(CROSS_BINUTILS).$(CROSS_BINUTILS_SUFFIX)
CROSS_BINUTILS_SOURCE	:= $(SRCDIR)/$(CROSS_BINUTILS).$(CROSS_BINUTILS_SUFFIX)
CROSS_BINUTILS_DIR	:= $(CROSS_BUILDDIR)/$(CROSS_BINUTILS)
CROSS_BINUTILS_BUILDDIR	:= $(CROSS_BUILDDIR)/$(CROSS_BINUTILS)-build

# ----------------------------------------------------------------------------
# Get
# ----------------------------------------------------------------------------

$(CROSS_BINUTILS_SOURCE):
	@$(call targetinfo)
	@$(call get, CROSS_BINUTILS)

# ----------------------------------------------------------------------------
# Extract
# ----------------------------------------------------------------------------

$(STATEDIR)/cross-binutils.extract:
	@$(call targetinfo)
	@$(call clean, $(CROSS_BINUTILS_DIR))
	@$(call extract, CROSS_BINUTILS, $(CROSS_BUILDDIR))
	@$(call patchin, CROSS_BINUTILS, $(CROSS_BINUTILS_DIR))
	@$(call touch)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

CROSS_BINUTILS_PATH	:= PATH=$(CROSS_PATH)
CROSS_BINUTILS_ENV 	:= $(HOST_ENV)

#
# autoconf
#
CROSS_BINUTILS_AUTOCONF := \
	--prefix=$(PTXCONF_SYSROOT_CROSS) \
	--target=$(PTXCONF_GNU_TARGET) \
	--disable-werror \
	--disable-nls

# for all other architecture than AVR a sysroot is required
ifndef PTXCONF_ARCH_AVR
CROSS_BINUTILS_AUTOCONF += --with-sysroot=$(SYSROOT)
endif

$(STATEDIR)/cross-binutils.prepare:
	@$(call targetinfo)
	rm -fr $(CROSS_BINUTILS_BUILDDIR)
	mkdir -p $(CROSS_BINUTILS_BUILDDIR)
	cd $(CROSS_BINUTILS_BUILDDIR) && \
		$(CROSS_BINUTILS_PATH) $(CROSS_BINUTILS_ENV) \
		$(CROSS_BINUTILS_DIR)/configure $(CROSS_BINUTILS_AUTOCONF)
	@$(call touch)

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

$(STATEDIR)/cross-binutils.compile:
	@$(call targetinfo)
	cd $(CROSS_BINUTILS_BUILDDIR) && $(CROSS_BINUTILS_PATH) \
		$(MAKE) $(PARALLELMFLAGS)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

$(STATEDIR)/cross-binutils.install:
	@$(call targetinfo)
	@$(call install, CROSS_BINUTILS,$(CROSS_BINUTILS_BUILDDIR),h)
	@$(call touch)

# ----------------------------------------------------------------------------
# Clean
# ----------------------------------------------------------------------------

cross-binutils_clean:
	rm -rf $(STATEDIR)/cross-binutils.*
	rm -rf $(CROSS_BINUTILS_DIR)

# vim: syntax=make

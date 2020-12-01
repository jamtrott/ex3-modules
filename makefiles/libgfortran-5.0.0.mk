# ex3modules - Makefiles for installing software on the eX3 cluster
# Copyright (C) 2020 James D. Trotter
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Authors: James D. Trotter <james@simula.no>
#
# libgfortran-5.0.0

libgfortran-version = 5.0.0
libgfortran = libgfortran-$(libgfortran-version)
$(libgfortran)-description = GNU Fortran Runtime Library
$(libgfortran)-url = https://gcc.gnu.org/
$(libgfortran)-srcurl =
$(libgfortran)-builddeps = $(gcc-10.1.0)
$(libgfortran)-prereqs =
$(libgfortran)-src =
$(libgfortran)-srcdir = $(pkgsrcdir)/$(libgfortran)
$(libgfortran)-builddir = $($(libgfortran)-srcdir)
$(libgfortran)-modulefile = $(modulefilesdir)/$(libgfortran)
$(libgfortran)-prefix = $(pkgdir)/$(libgfortran)

$($(libgfortran)-srcdir)/.markerfile:
	$(INSTALL) -m=6755 -d $(dir $@) && touch $@

$($(libgfortran)-prefix)/.markerfile:
	$(INSTALL) -m=6755 -d $(dir $@) && touch $@

$($(libgfortran)-prefix)/.pkgunpack: $$($(libgfortran)-src) $($(libgfortran)-srcdir)/.markerfile $($(libgfortran)-prefix)/.markerfile
	@touch $@

$($(libgfortran)-prefix)/.pkgpatch: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(libgfortran)-builddeps),$(modulefilesdir)/$$(dep)) $($(libgfortran)-prefix)/.pkgunpack
	@touch $@

ifneq ($($(libgfortran)-builddir),$($(libgfortran)-srcdir))
$($(libgfortran)-builddir)/.markerfile: $($(libgfortran)-prefix)/.pkgunpack
	$(INSTALL) -m=6755 -d $(dir $@) && touch $@
endif

$($(libgfortran)-prefix)/.pkgbuild: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(libgfortran)-builddeps),$(modulefilesdir)/$$(dep)) $($(libgfortran)-builddir)/.markerfile $($(libgfortran)-prefix)/.pkgpatch
	@touch $@

$($(libgfortran)-prefix)/.pkgcheck: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(libgfortran)-builddeps),$(modulefilesdir)/$$(dep)) $($(libgfortran)-builddir)/.markerfile $($(libgfortran)-prefix)/.pkgbuild
	@touch $@

$($(libgfortran)-prefix)/.pkginstall: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(libgfortran)-builddeps),$(modulefilesdir)/$$(dep)) $($(libgfortran)-builddir)/.markerfile $($(libgfortran)-prefix)/.pkgcheck
	@touch $@

$($(libgfortran)-modulefile): $(modulefilesdir)/.markerfile $($(libgfortran)-prefix)/.pkginstall
	printf "" >$@
	echo "#%Module" >>$@
	echo "# $(libgfortran)" >>$@
	echo "" >>$@
	echo "proc ModulesHelp { } {" >>$@
	echo "     puts stderr \"\tSets up the environment for $(libgfortran)\\n\"" >>$@
	echo "}" >>$@
	echo "" >>$@
	echo "module-whatis \"$($(libgfortran)-description)\"" >>$@
	echo "module-whatis \"$($(libgfortran)-url)\"" >>$@
	printf "$(foreach prereq,$($(libgfortran)-prereqs),\n$(MODULE) load $(prereq))" >>$@
	echo "" >>$@
	echo "" >>$@
	echo "setenv LIBGFORTRAN_ROOT $($(gcc-10.1.0)-prefix)" >>$@
	echo "setenv LIBGFORTRAN_INCDIR $($(gcc-10.1.0)-prefix)/include" >>$@
	echo "setenv LIBGFORTRAN_INCLUDEDIR $($(gcc-10.1.0)-prefix)/include" >>$@
	echo "setenv LIBGFORTRAN_LIBDIR $($(gcc-10.1.0)-prefix)/lib" >>$@
	echo "setenv LIBGFORTRAN_LIBRARYDIR $($(gcc-10.1.0)-prefix)/lib" >>$@
	echo "prepend-path LIBRARY_PATH $($(gcc-10.1.0)-prefix)/lib64" >>$@
	echo "prepend-path LD_LIBRARY_PATH $($(gcc-10.1.0)-prefix)/lib64" >>$@
	echo "set MSG \"$(libgfortran)\"" >>$@

$(libgfortran)-src: $$($(libgfortran)-src)
$(libgfortran)-unpack: $($(libgfortran)-prefix)/.pkgunpack
$(libgfortran)-patch: $($(libgfortran)-prefix)/.pkgpatch
$(libgfortran)-build: $($(libgfortran)-prefix)/.pkgbuild
$(libgfortran)-check: $($(libgfortran)-prefix)/.pkgcheck
$(libgfortran)-install: $($(libgfortran)-prefix)/.pkginstall
$(libgfortran)-modulefile: $($(libgfortran)-modulefile)
$(libgfortran)-clean:
	rm -rf $($(libgfortran)-modulefile)
	rm -rf $($(libgfortran)-srcdir)
$(libgfortran): $(libgfortran)-src $(libgfortran)-unpack $(libgfortran)-patch $(libgfortran)-build $(libgfortran)-check $(libgfortran)-install $(libgfortran)-modulefile

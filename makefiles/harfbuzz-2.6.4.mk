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
# harfbuzz-2.6.4

harfbuzz-version = 2.6.4
harfbuzz = harfbuzz-$(harfbuzz-version)
$(harfbuzz)-description = Text shaping engine
$(harfbuzz)-url = https://www.freedesktop.org/wiki/Software/HarfBuzz/
$(harfbuzz)-srcurl = https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-$(harfbuzz-version).tar.xz
$(harfbuzz)-src = $(pkgsrcdir)/$(notdir $($(harfbuzz)-srcurl))
$(harfbuzz)-srcdir = $(pkgsrcdir)/$(harfbuzz)
$(harfbuzz)-builddeps = $(fontconfig) $(freetype) $(cairo) $(glib)
$(harfbuzz)-prereqs = $(fontconfig) $(freetype) $(cairo) $(glib)
$(harfbuzz)-modulefile = $(modulefilesdir)/$(harfbuzz)
$(harfbuzz)-prefix = $(pkgdir)/$(harfbuzz)

$($(harfbuzz)-src): $(dir $($(harfbuzz)-src)).markerfile
	$(CURL) $(curl_options) --output $@ $($(harfbuzz)-srcurl)

$($(harfbuzz)-srcdir)/.markerfile:
	$(INSTALL) -m=6755 -d $(dir $@) && touch $@

$($(harfbuzz)-prefix)/.markerfile:
	$(INSTALL) -m=6755 -d $(dir $@) && touch $@

$($(harfbuzz)-prefix)/.pkgunpack: $($(harfbuzz)-src) $($(harfbuzz)-srcdir)/.markerfile $($(harfbuzz)-prefix)/.markerfile
	tar -C $($(harfbuzz)-srcdir) --strip-components 1 -x -f $<
	@touch $@

$($(harfbuzz)-prefix)/.pkgpatch: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(harfbuzz)-builddeps),$(modulefilesdir)/$$(dep)) $($(harfbuzz)-prefix)/.pkgunpack
	@touch $@

$($(harfbuzz)-prefix)/.pkgbuild: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(harfbuzz)-builddeps),$(modulefilesdir)/$$(dep)) $($(harfbuzz)-prefix)/.pkgpatch
	cd $($(harfbuzz)-srcdir) && \
		$(MODULESINIT) && \
		$(MODULE) use $(modulefilesdir) && \
		$(MODULE) load $($(harfbuzz)-builddeps) && \
		./configure --prefix=$($(harfbuzz)-prefix) && \
		$(MAKE)
	@touch $@

$($(harfbuzz)-prefix)/.pkgcheck: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(harfbuzz)-builddeps),$(modulefilesdir)/$$(dep)) $($(harfbuzz)-prefix)/.pkgbuild
	cd $($(harfbuzz)-srcdir) && \
		$(MODULESINIT) && \
		$(MODULE) use $(modulefilesdir) && \
		$(MODULE) load $($(harfbuzz)-builddeps) && \
		$(MAKE) check
	@touch $@

$($(harfbuzz)-prefix)/.pkginstall: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(harfbuzz)-builddeps),$(modulefilesdir)/$$(dep)) $($(harfbuzz)-prefix)/.pkgcheck
	$(MAKE) -C $($(harfbuzz)-srcdir) install
	@touch $@

$($(harfbuzz)-modulefile): $(modulefilesdir)/.markerfile $($(harfbuzz)-prefix)/.pkginstall
	printf "" >$@
	echo "#%Module" >>$@
	echo "# $(harfbuzz)" >>$@
	echo "" >>$@
	echo "proc ModulesHelp { } {" >>$@
	echo "     puts stderr \"\tSets up the environment for $(harfbuzz)\\n\"" >>$@
	echo "}" >>$@
	echo "" >>$@
	echo "module-whatis \"$($(harfbuzz)-description)\"" >>$@
	echo "module-whatis \"$($(harfbuzz)-url)\"" >>$@
	printf "$(foreach prereq,$($(harfbuzz)-prereqs),\n$(MODULE) load $(prereq))" >>$@
	echo "" >>$@
	echo "" >>$@
	echo "setenv HARFBUZZ_ROOT $($(harfbuzz)-prefix)" >>$@
	echo "setenv HARFBUZZ_INCDIR $($(harfbuzz)-prefix)/include" >>$@
	echo "setenv HARFBUZZ_INCLUDEDIR $($(harfbuzz)-prefix)/include" >>$@
	echo "setenv HARFBUZZ_LIBDIR $($(harfbuzz)-prefix)/lib" >>$@
	echo "setenv HARFBUZZ_LIBRARYDIR $($(harfbuzz)-prefix)/lib" >>$@
	echo "prepend-path PATH $($(harfbuzz)-prefix)/bin" >>$@
	echo "prepend-path C_INCLUDE_PATH $($(harfbuzz)-prefix)/include" >>$@
	echo "prepend-path CPLUS_INCLUDE_PATH $($(harfbuzz)-prefix)/include" >>$@
	echo "prepend-path LIBRARY_PATH $($(harfbuzz)-prefix)/lib" >>$@
	echo "prepend-path LD_LIBRARY_PATH $($(harfbuzz)-prefix)/lib" >>$@
	echo "prepend-path PKG_CONFIG_PATH $($(harfbuzz)-prefix)/lib/pkgconfig" >>$@
	echo "prepend-path MANPATH $($(harfbuzz)-prefix)/share/man" >>$@
	echo "prepend-path INFOPATH $($(harfbuzz)-prefix)/share/info" >>$@
	echo "set MSG \"$(harfbuzz)\"" >>$@

$(harfbuzz)-src: $($(harfbuzz)-src)
$(harfbuzz)-unpack: $($(harfbuzz)-prefix)/.pkgunpack
$(harfbuzz)-patch: $($(harfbuzz)-prefix)/.pkgpatch
$(harfbuzz)-build: $($(harfbuzz)-prefix)/.pkgbuild
$(harfbuzz)-check: $($(harfbuzz)-prefix)/.pkgcheck
$(harfbuzz)-install: $($(harfbuzz)-prefix)/.pkginstall
$(harfbuzz)-modulefile: $($(harfbuzz)-modulefile)
$(harfbuzz)-clean:
	rm -rf $($(harfbuzz)-modulefile)
	rm -rf $($(harfbuzz)-prefix)
	rm -rf $($(harfbuzz)-srcdir)
	rm -rf $($(harfbuzz)-src)
$(harfbuzz): $(harfbuzz)-src $(harfbuzz)-unpack $(harfbuzz)-patch $(harfbuzz)-build $(harfbuzz)-check $(harfbuzz)-install $(harfbuzz)-modulefile

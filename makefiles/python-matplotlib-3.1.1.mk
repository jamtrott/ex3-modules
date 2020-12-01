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
# python-matplotlib-3.1.1

python-matplotlib-version = 3.1.1
python-matplotlib = python-matplotlib-$(python-matplotlib-version)
$(python-matplotlib)-description = 2D plotting library
$(python-matplotlib)-url = https://matplotlib.org/
$(python-matplotlib)-srcurl = https://files.pythonhosted.org/packages/12/d1/7b12cd79c791348cb0c78ce6e7d16bd72992f13c9f1e8e43d2725a6d8adf/matplotlib-3.1.1.tar.gz
$(python-matplotlib)-src = $(pkgsrcdir)/$(notdir $($(python-matplotlib)-srcurl))
$(python-matplotlib)-srcdir = $(pkgsrcdir)/$(python-matplotlib)
$(python-matplotlib)-builddeps = $(python) $(freetype) $(libpng) $(blas) $(mpi) $(python-numpy) $(python-kiwisolver) $(python-dateutil) $(python-pytest) $(python-cycler) $(python-pyparsing)
$(python-matplotlib)-prereqs = $(python) $(freetype) $(libpng) $(python-numpy) $(python-kiwisolver) $(python-dateutil) $(python-pyparsing)
$(python-matplotlib)-modulefile = $(modulefilesdir)/$(python-matplotlib)
$(python-matplotlib)-prefix = $(pkgdir)/$(python-matplotlib)
$(python-matplotlib)-site-packages = $($(python-matplotlib)-prefix)/lib/python$(python-version-short)/site-packages

$($(python-matplotlib)-src): $(dir $($(python-matplotlib)-src)).markerfile
	$(CURL) $(curl_options) --output $@ $($(python-matplotlib)-srcurl)

$($(python-matplotlib)-srcdir)/.markerfile:
	$(INSTALL) -m=6755 -d $(dir $@) && touch $@

$($(python-matplotlib)-prefix)/.markerfile:
	$(INSTALL) -m=6755 -d $(dir $@) && touch $@

$($(python-matplotlib)-prefix)/.pkgunpack: $$($(python-matplotlib)-src) $($(python-matplotlib)-srcdir)/.markerfile $($(python-matplotlib)-prefix)/.markerfile
	tar -C $($(python-matplotlib)-srcdir) --strip-components 1 -xz -f $<
	@touch $@

$($(python-matplotlib)-prefix)/.pkgpatch: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(python-matplotlib)-builddeps),$(modulefilesdir)/$$(dep)) $($(python-matplotlib)-prefix)/.pkgunpack
	@touch $@

$($(python-matplotlib)-site-packages)/.markerfile:
	$(INSTALL) -m=6755 -d $(dir $@)
	@touch $@

$($(python-matplotlib)-prefix)/.pkgbuild: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(python-matplotlib)-builddeps),$(modulefilesdir)/$$(dep)) $($(python-matplotlib)-prefix)/.pkgpatch
	cd $($(python-matplotlib)-srcdir) && \
		$(MODULESINIT) && \
		$(MODULE) use $(modulefilesdir) && \
		$(MODULE) load $($(python-matplotlib)-builddeps) && \
		python3 setup.py build
	@touch $@

$($(python-matplotlib)-prefix)/.pkgcheck: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(python-matplotlib)-builddeps),$(modulefilesdir)/$$(dep)) $($(python-matplotlib)-prefix)/.pkgbuild
	# cd $($(python-matplotlib)-srcdir) && \
	# 	$(MODULE) use $(modulefilesdir) && \
	# 	$(MODULE) load $($(python-matplotlib)-builddeps) && \
	# 	pytest
	@touch $@

$($(python-matplotlib)-prefix)/.pkginstall: $(modulefilesdir)/.markerfile $$(foreach dep,$$($(python-matplotlib)-builddeps),$(modulefilesdir)/$$(dep)) $($(python-matplotlib)-prefix)/.pkgcheck $($(python-matplotlib)-site-packages)/.markerfile
	cd $($(python-matplotlib)-srcdir) && \
		$(MODULESINIT) && \
		$(MODULE) use $(modulefilesdir) && \
		$(MODULE) load $($(python-matplotlib)-builddeps) && \
		PYTHONPATH=$($(python-matplotlib)-site-packages):$${PYTHONPATH} \
		python3 setup.py install --prefix=$($(python-matplotlib)-prefix)
	@touch $@

$($(python-matplotlib)-modulefile): $(modulefilesdir)/.markerfile $($(python-matplotlib)-prefix)/.pkgcheck $($(python-matplotlib)-prefix)/.pkginstall
	printf "" >$@
	echo "#%Module" >>$@
	echo "# $(python-matplotlib)" >>$@
	echo "" >>$@
	echo "proc ModulesHelp { } {" >>$@
	echo "     puts stderr \"\tSets up the environment for $(python-matplotlib)\\n\"" >>$@
	echo "}" >>$@
	echo "" >>$@
	echo "module-whatis \"$($(python-matplotlib)-description)\"" >>$@
	echo "module-whatis \"$($(python-matplotlib)-url)\"" >>$@
	printf "$(foreach prereq,$($(python-matplotlib)-prereqs),\n$(MODULE) load $(prereq))" >>$@
	echo "" >>$@
	echo "" >>$@
	echo "setenv PYTHON_MATPLOTLIB_ROOT $($(python-matplotlib)-prefix)" >>$@
	echo "prepend-path PATH $($(python-matplotlib)-prefix)/bin" >>$@
	echo "prepend-path PYTHONPATH $($(python-matplotlib)-site-packages)" >>$@
	echo "set MSG \"$(python-matplotlib)\"" >>$@

$(python-matplotlib)-src: $($(python-matplotlib)-src)
$(python-matplotlib)-unpack: $($(python-matplotlib)-prefix)/.pkgunpack
$(python-matplotlib)-patch: $($(python-matplotlib)-prefix)/.pkgpatch
$(python-matplotlib)-build: $($(python-matplotlib)-prefix)/.pkgbuild
$(python-matplotlib)-check: $($(python-matplotlib)-prefix)/.pkgcheck
$(python-matplotlib)-install: $($(python-matplotlib)-prefix)/.pkginstall
$(python-matplotlib)-modulefile: $($(python-matplotlib)-modulefile)
$(python-matplotlib)-clean:
	rm -rf $($(python-matplotlib)-modulefile)
	rm -rf $($(python-matplotlib)-prefix)
	rm -rf $($(python-matplotlib)-srcdir)
	rm -rf $($(python-matplotlib)-src)
$(python-matplotlib): $(python-matplotlib)-src $(python-matplotlib)-unpack $(python-matplotlib)-patch $(python-matplotlib)-build $(python-matplotlib)-check $(python-matplotlib)-install $(python-matplotlib)-modulefile

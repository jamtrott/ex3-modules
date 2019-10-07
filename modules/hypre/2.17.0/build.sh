#!/usr/bin/env bash
#
# Build hypre
#
# The following command will build the module, write a module file,
# and install them to the directory 'modules' in your home directory:
#
#   build.sh --prefix=$HOME/modules 2>&1 | tee build.log
#
# The module can then be loaded as follows:
#
#   module use $HOME/modules/modulefiles
#   module load hypre
#
set -o errexit

. ../../../common/module.sh

pkg_name=hypre
pkg_version=2.17.0
pkg_moduledir="${pkg_name}/${pkg_version}"
pkg_description="Scalable Linear Solvers and Multigrid Methods"
pkg_url="https://github.com/hypre-space/hypre"
src_url="https://github.com/hypre-space/hypre/archive/v${pkg_version}.tar.gz"
src_dir="${pkg_name}-${pkg_version}/src"

function main()
{
    # Parse program options
    module_build_parse_command_line_args \
	"${0}" \
	"${pkg_name}" \
	"${pkg_version}" \
	"${pkg_moduledir}" \
	"${pkg_description}" \
	"${pkg_url}" \
	"$@"

    # Load build-time dependencies and determine prerequisite modules
    module_load_build_deps build_deps
    pkg_prereqs=$(module_prereqs prereqs)

    # Download and unpack source
    pkg_prefix=$(module_build_prefix "${prefix}" "${pkg_moduledir}")
    pkg_build_dir=$(module_build_create_build_dir "${pkg_name}" "${pkg_version}")
    pkg_src="${pkg_build_dir}/$(basename ${src_url})"
    module_build_download_package "${src_url}" "${pkg_src}"
    module_build_unpack "${pkg_src}" "${pkg_build_dir}"

    # Build
    pushd "${pkg_build_dir}/${src_dir}"

    # Apply some fixes to enable building with DESTDIR
    grep -lr "\${HYPRE_LIB_INSTALL}" . | xargs sed -i 's,${HYPRE_LIB_INSTALL},${DESTDIR}${HYPRE_LIB_INSTALL},'
    grep -lr "\${HYPRE_INC_INSTALL}" . | xargs sed -i 's,${HYPRE_INC_INSTALL},${DESTDIR}${HYPRE_INC_INSTALL},'

    ./configure \
	--prefix="${pkg_prefix}" \
	--enable-shared \
	--with-blas-lib-dirs="${BLASDIR}" --with-blas-libs="${BLASLIB}" \
	--with-lapack-lib-dirs="${BLASDIR}" --with-lapack-libs="${BLASLIB}" \
	CFLAGS="-O3"
    make -j"${JOBS}"
    make install
    popd

    # Write the module file
    pkg_modulefile=$(module_build_modulefile "${prefix}" "${modulefilesdir}" "${pkg_moduledir}")
    cat >"${pkg_modulefile}" <<EOF
#%Module
# ${pkg_name} ${pkg_version}

proc ModulesHelp { } {
     puts stderr "\tSets up the environment for ${pkg_name} ${pkg_version}\n"
}

module-whatis "${pkg_description}"
module-whatis "${pkg_url}"

${pkg_prereqs}

set MODULES_PREFIX [getenv MODULES_PREFIX ""]
setenv ${pkg_name^^}_ROOT \$MODULES_PREFIX${pkg_prefix}
setenv ${pkg_name^^}_INCDIR \$MODULES_PREFIX${pkg_prefix}/include
setenv ${pkg_name^^}_INCLUDEDIR \$MODULES_PREFIX${pkg_prefix}/include
setenv ${pkg_name^^}_LIBDIR \$MODULES_PREFIX${pkg_prefix}/lib
setenv ${pkg_name^^}_LIBRARYDIR \$MODULES_PREFIX${pkg_prefix}/lib
prepend-path C_INCLUDE_PATH \$MODULES_PREFIX${pkg_prefix}/include
prepend-path CPLUS_INCLUDE_PATH \$MODULES_PREFIX${pkg_prefix}/include
prepend-path LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/lib
prepend-path LD_LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/lib
set MSG "${pkg_name} ${pkg_version}"
EOF

    module_build_cleanup "${pkg_build_dir}"
}

main "$@"
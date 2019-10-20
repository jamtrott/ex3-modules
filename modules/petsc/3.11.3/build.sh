#!/usr/bin/env bash
#
# Build petsc
#
# The following command will build the module, write a module file,
# and install them to the directory 'modules' in your home directory:
#
#   build.sh --prefix=$HOME/modules 2>&1 | tee build.log
#
# The module can then be loaded as follows:
#
#   module use $HOME/modules/modulefiles
#   module load petsc
#
set -o errexit

pkg_name=petsc
pkg_version=3.11.3
pkg_moduledir="${pkg_name}/${pkg_version}"
pkg_description="Portable, Extensible Toolkit for Scientific Computation"
pkg_url="https://www.mcs.anl.gov/petsc/"
src_url="http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-${pkg_version}.tar.gz"
src_dir="${pkg_name}-${pkg_version}"

function main()
{
    . ../../../common/module.sh

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
    COPTFLAGS="-O3"
    CXXOPTFLAGS="-O3"
    FOPTFLAGS="-O3"
    python3 ./configure \
	--prefix="${pkg_prefix}" \
	--with-cxx-dialect=C++11 \
	--with-openmp=1 \
	--with-blaslapack-lib="${BLASDIR}/lib${BLASLIB}.so" \
	--with-boost --with-boost-dir="${BOOST_ROOT}" \
	--with-hwloc --with-hwloc-dir="${HWLOC_ROOT}" \
	--with-hypre --with-hypre-dir="${HYPRE_ROOT}" \
	--with-metis --with-metis-dir="${METIS_ROOT}" \
	--with-mpi --with-mpi-dir="${OPENMPI_ROOT}" \
	--with-mumps --with-mumps-dir="${MUMPS_ROOT}" \
	--with-parmetis --with-parmetis-dir="${PARMETIS_ROOT}" \
	--with-ptscotch --with-ptscotch-dir="${SCOTCH_ROOT}" --with-ptscotch-libs=libz.so \
	--with-scalapack --with-scalapack-dir="${SCALAPACK_ROOT}" \
	--with-suitesparse --with-suitesparse-dir="${SUITESPARSE_ROOT}" \
	--with-superlu --with-superlu-dir="${SUPERLU_ROOT}" \
	--with-superlu_dist --with-superlu_dist-dir="${SUPERLU_DIST_ROOT}" \
	--with-x=0 \
	--with-debugging=0 \
	COPTFLAGS="${COPTFLAGS}" \
	CXXOPTFLAGS="${CXXOPTFLAGS}" \
	FOPTFLAGS="${FOPTFLAGS}"
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

setenv ${pkg_name^^}_ROOT ${pkg_prefix}
setenv ${pkg_name^^}_DIR ${pkg_prefix}
setenv ${pkg_name^^}_INCDIR ${pkg_prefix}/include
setenv ${pkg_name^^}_INCLUDEDIR ${pkg_prefix}/include
setenv ${pkg_name^^}_LIBDIR ${pkg_prefix}/lib
setenv ${pkg_name^^}_LIBRARYDIR ${pkg_prefix}/lib
prepend-path C_INCLUDE_PATH ${pkg_prefix}/include
prepend-path CPLUS_INCLUDE_PATH ${pkg_prefix}/include
prepend-path LIBRARY_PATH ${pkg_prefix}/lib
prepend-path LD_LIBRARY_PATH ${pkg_prefix}/lib
prepend-path PKG_CONFIG_PATH ${pkg_prefix}/lib/pkgconfig
set MSG "${pkg_name} ${pkg_version}"
EOF

    module_build_cleanup "${pkg_build_dir}"
}

main "$@"

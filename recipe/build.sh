#!/bin/bash

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib

[[ ${target_platform} == "linux-64" ]] && targetsDir="targets/x86_64-linux"
[[ ${target_platform} == "linux-ppc64le" ]] && targetsDir="targets/ppc64le-linux"
[[ ${target_platform} == "linux-aarch64" ]] && targetsDir="targets/sbsa-linux"

for i in `ls`; do
    [[ $i == "build_env_setup.sh" ]] && continue
    [[ $i == "conda_build.sh" ]] && continue
    [[ $i == "metadata_conda_debug.yaml" ]] && continue
    if [[ $i == "bin" ]] || [[ $i == "lib" ]] || [[ $i == "include" ]] || [[ $i == "nvvm" ]]; then
        # Headers and libraries are installed to targetsDir
        mkdir -p ${PREFIX}/${targetsDir}
        mkdir -p ${PREFIX}/$i
        cp -rv $i ${PREFIX}/${targetsDir}
        if [[ $i == "bin" ]]; then
            # Use a custom nvcc.profile to handle the fact that nvcc is a symlink.
            cp ${RECIPE_DIR}/nvcc.profile.for_prefix_bin ${PREFIX}/bin/nvcc.profile
            ln -sv ${PREFIX}/${targetsDir}/bin/nvcc ${PREFIX}/bin/nvcc
            ln -sv ${PREFIX}/${targetsDir}/bin/crt ${PREFIX}/bin/crt
        elif [[ $i == "lib" ]]; then
            for j in "$i"/*.a*; do
                # Static libraries are symlinked in $PREFIX/lib
                ln -sv ${PREFIX}/${targetsDir}/$j ${PREFIX}/$j
            done
            ln -sv ${PREFIX}/${targetsDir}/lib ${PREFIX}/${targetsDir}/lib64
        elif [[ $i == "nvvm" ]]; then
            for j in "$i"/*; do
                ln -sv ${PREFIX}/${targetsDir}/$j ${PREFIX}/$j
            done
        fi
    else
        cp -rv $i ${PREFIX}/${targetsDir}
    fi
done

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
# Name this script starting with `~` so it is run after all other compiler activation scripts.
# At the point of running this, $CXX must be defined.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/~${PKG_NAME}_${CHANGE}.sh"
done

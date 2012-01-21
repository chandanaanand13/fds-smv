#!/bin/csh -f
#
# this script is called from windows which passes in the directory containing this script
#
setenv fds_smvroot $1
setenv bundlebase $2
setenv runhost $3
setenv fdshost $3
setenv smvhost $3
setenv PLATFORM LINUX32


setenv manifest manifest_linux_32.html

setenv INTELLIB /shared/LIB32
setenv smokezipdir intel_linux_32
setenv smokediffdir intel_linux_32
setenv fdsdir intel_linux_32
setenv fdsmpidir mpi_intel_linux_32

setenv smokeviewdir intel_linux_32
setenv smokeview smokeview_linux_32
setenv smokezip smokezip_linux_32
setenv smokediff smokediff_linux_32

setenv fds fds_intel_linux_32
setenv fdsmpi fds_mpi_intel_linux_32

setenv fdsout fds_linux_32
setenv fdsmpiout fds_mpi_linux_32

setenv fds2ascii fds2ascii_linux_32
setenv fds2asciidir intel_linux_32

$fds_smvroot/Utilities/Scripts/bundle_generic.csh



#!/bin/bash

get_replace()
{
    local var="${1}"

    if [ "${!var}" = "y" ]; then
	echo "-e \"s~\# \(${var}\) is not set.*~\1=${!var}~\""
	#FIXME turn it off again
    else
	echo "-e \"s~\(${var}\)=.*~\1=\\\"${!var}\\\"~\""
    fi
}

fixup() {
    local config="${1}"

    touple="${config##*/}"
    touple="${touple%.ptxconfig}"

    local ifs_old="${IFS}"
    IFS="_"
    set -- ${touple}
    IFS="${ifs_orig}"

    while [ ${#} -ne 0 ]; do
	part="${1}"
	shift

	case "${part}" in
	    gcc*)
		PTXCONF_CROSS_GCC_VERSION="${part##gcc-}"
		;;
	    glibc*)
		PTXCONF_GLIBC_VERSION="${part##glibc-}"
		;;
	    libc*)
		PTXCONF_AVRLIB_VERSION="${part##libc-}"
		;;
	    binutils*)
		PTXCONF_CROSS_BINUTILS_VERSION="${part##binutils-}"
		;;
	    linux*)
		PTXCONF_KERNEL_HEADERS_VERSION="${part##linux-}"
		PTXCONF_KERNEL_HEADERS_VERSION="${PTXCONF_KERNEL_HEADERS_VERSION%-sanitized}"

		case "${part}" in
		    *-sanitized)
			PTXCONF_KERNEL_HEADERS_SANITIZED=y
			;;
		esac
		;;
	    j*)
		PTXCONF_CROSS_GCC_LANG_JAVA=y
		;;
	    *)
		PTXCONF_GNU_TARGET="${PTXCONF_GNU_TARGET}${PTXCONF_GNU_TARGET:+_}${part}"
		;;
	esac
    done

    # version
    PTXCONF_CONFIGFILE_VERSION="1.99.6"
    PTXCONF_PROJECT="${PWD}"
    PTXCONF_PROJECT="${PTXCONF_PROJECT##*/}"

    # defaults
    PTXCONF_PREFIX="/opt"
    PTXCONF_GLIBC_EXTRA_CONFIG=""
    PTXCONF_GLIBC_TIMESTAMP=""

    # ARM eabi hack
    case "${PTXCONF_GNU_TARGET}" in
	arm*gnueabi)
	    PTXCONF_GLIBC_HEADERS_FAKE_CROSS="-D__ARM_EABI__"
	    ;;
	mips*)
	    PTXCONF_GLIBC_HEADERS_FAKE_CROSS="-DBOOTSTRAP_GCC"
	    ;;
	*)
	    ;;
    esac

    case "${PTXCONF_GNU_TARGET}" in
	# hard fpa
	arm-v4t_hardfloat-linux-gnu)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-float=hard	--with-fpu=fpa				--with-arch=armv4t"
	    ;;
	arm-xscale_hardfloat-linux-gnu)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-float=hard	--with-fpu=fpa	--with-cpu=xscale"
	    ;;

	# softfp, vfp
	arm-1136jfs-linux-gnueabi)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-float=softfp	--with-fpu=vfp	--with-cpu=arm1136jf-s"
	    ;;

	# soft, vfp
	armeb-xscale-linux-gnueabi|armeb-xscale-linux-gnu)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-float=soft	--with-fpu=vfp	--with-cpu=xscale"
	    PTXCONF_GLIBC_EXTRA_CONFIG="--without-fp"
	    ;;
	arm-iwmmx-linux-gnueabi)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-float=soft	--with-fpu=vfp	--with-cpu=iwmmxt"
	    PTXCONF_GLIBC_EXTRA_CONFIG="--without-fp"
	    ;;
	arm-v4t-linux-gnueabi|arm-v4t-linux-gnu)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-float=soft	--with-fpu=vfp				--with-arch=armv4t"
	    PTXCONF_GLIBC_EXTRA_CONFIG="--without-fp"
	    ;;
	arm-v5te-linux-gnueabi)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-float=soft	--with-fpu=vfp	--with-cpu=arm926ej-s	--with-arch=armv5te"
	    PTXCONF_GLIBC_EXTRA_CONFIG="--without-fp"
	    ;;
	arm-xscale-linux-gnueabi|arm-xscale-linux-gnu)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-float=soft	--with-fpu=vfp	--with-cpu=xscale"
	    PTXCONF_GLIBC_EXTRA_CONFIG="--without-fp"
	    ;;


	i586-unknown-linux-gnu)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-arch=i586"
	    ;;
	i686-unknown-linux-gnu)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-arch=i686"
	    ;;

	mipsel-softfloat-linux-gnu)
	    PTXCONF_GLIBC_EXTRA_CONFIG="--without-fp"
	    ;;
	powerpc-603e-linux-gnu)
	    PTXCONF_CROSS_GCC_EXTRA_CONFIG="--with-cpu=603e	--disable-altivec"
	    ;;

	avr)
	    ;;

	*)
	    echo "unknown target: ${PTXCONF_GNU_TARGET}"
	    exit 1
	    ;;
    esac

    case "${PTXCONF_KERNEL_HEADERS_VERSION}" in
	2.6.18)
	    PTXCONF_GLIBC_ENABLE_KERNEL="2.6.16"
	    ;;
	2.6.26)
	    PTXCONF_GLIBC_ENABLE_KERNEL="2.6.23"
	    ;;
	*)
	    ;;
    esac


    clear

    local sed_magic=""
    for var in ${!PTXCONF_@}; do
	# remove tabs :)
	eval "${var}"=\"$(echo ${!var} | sed -e "s/[\t]\+/ /g")\"

	echo "${var}"="${!var}"
	sed_magic="${sed_magic} $(get_replace "${var}")"
	unset "${var}"
    done

    eval sed -i "${sed_magic}" "${config}"

    if [ -e selected_ptxconfig ]; then
	rm selected_ptxconfig
    fi

    echo
    echo
    echo

    ptxdist --force-config select ${config}
    ptxdist oldconfig

}

#
# main()
#
if test -n "${1}"; then
    fixup ${1}
else
    for config in `find ptxconfigs -name "*.ptxconfig"`; do
	fixup ${config}
    done
fi

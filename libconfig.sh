# libconfig.sh
#
# Copyright (c) 2022 hinto.janaiyo <https://github.com/hinto-janaiyo>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#git <libconfig/libconfig.sh/99dc038>

config::source() {
	# init local variables
	local LIBCONFIG_LINE LIBCONFIG_ARG LIBCONFIG_TYPE IFS=$'\n' || return 1
	declare -a LIBCONFIG_ARRAY || return 1

	# check for correct arguments
	[[ $# -lt 3 ]] && return 2

	# check for odd/even arguments
	LIBCONFIG_ARG=$(($# % 2))
	[[ $LIBCONFIG_ARG = 0 ]] && return 3

	# check if config is a file
	[[ -f "$1" ]] || return 4
	# check for read permission
	[[ -r "$1" ]] || return 5

	# create line array of file
	mapfile LIBCONFIG_ARRAY < "$1" || return 6
	# convert to string
	printf -v LIBCONFIG_ARRAY "%s" "${LIBCONFIG_ARRAY[@]}"
	# shift config file
	shift
	# strip quotes
	LIBCONFIG_ARRAY=${LIBCONFIG_ARRAY//\"}
	LIBCONFIG_ARRAY=${LIBCONFIG_ARRAY//\'}

	# loop over arguments
	until [[ $# = 0 ]]; do
		# loop over file per argument given
		case $1 in
			ip)
				for LIBCONFIG_LINE in $LIBCONFIG_ARRAY; do
					if [[ $LIBCONFIG_LINE = \#* ]]; then
						continue
					elif [[ $LIBCONFIG_LINE =~ ^${2}=[0-9.]+'.'[0-9]+$ ]]; then
						declare -g ${2//-/_}="${LIBCONFIG_LINE/*=/}" || return 7
					fi
				done
				shift 2;;
			int)
				for LIBCONFIG_LINE in $LIBCONFIG_ARRAY; do
					if [[ $LIBCONFIG_LINE = \#* ]]; then
						continue
					elif [[ $LIBCONFIG_LINE =~ ^${2}=[0-9]+$ ]]; then
						declare -g ${2//-/_}="${LIBCONFIG_LINE/*=/}" || return 7
					fi
				done
				shift 2;;
			port)
				for LIBCONFIG_LINE in $LIBCONFIG_ARRAY; do
					if [[ $LIBCONFIG_LINE = \#* ]]; then
						continue
					elif [[ $LIBCONFIG_LINE =~ ^${2}=[0-9:.]+'.'[0-9]':'[0-9]+$ ]]; then
						declare -g ${2//-/_}="${LIBCONFIG_LINE/*=/}" || return 7
					fi
				done
				shift 2;;
			bool)
				for LIBCONFIG_LINE in $LIBCONFIG_ARRAY; do
					if [[ $LIBCONFIG_LINE = \#* ]]; then
						continue
					elif [[ $LIBCONFIG_LINE =~ ^${2}=true$ || $LIBCONFIG_LINE =~ ^${2}=false$ ]]; then
						declare -g ${2//-/_}="${LIBCONFIG_LINE/*=/}" || return 7
					fi
				done
				shift 2;;
			char)
				for LIBCONFIG_LINE in $LIBCONFIG_ARRAY; do
					if [[ $LIBCONFIG_LINE = \#* ]]; then
						continue
					elif [[ $LIBCONFIG_LINE =~ ^${2}=[[:alnum:]._-]+$ ]]; then
						declare -g ${2//-/_}="${LIBCONFIG_LINE/*=/}" || return 7
					fi
				done
				shift 2;;
			path)
				for LIBCONFIG_LINE in $LIBCONFIG_ARRAY; do
					if [[ $LIBCONFIG_LINE = \#* ]]; then
						continue
					elif [[ $LIBCONFIG_LINE =~ ^${2}=[[:alnum:]./_-]+$ ]]; then
						declare -g ${2//-/_}="${LIBCONFIG_LINE/*=/}" || return 7
					fi
				done
				shift 2;;
		esac
	done
}

config::carry() {
	# init local variables.
	local i || return 1
	local -a LIBCONFIG_OLD LIBCONFIG_CMD || return 2

	# check amount of arguments
	case $# in
		2) :;;
		*) return 3
	esac

	# check if file
	[[ -f $1 ]] || return 3
	[[ -f $2 ]] || return 4

	# check for read permission
	[[ -r $1 ]] || return 5
	[[ -r $2 ]] || return 6

	# get old values from (a) in memory
	LIBCONFIG_OLD=($(sed "/^#.*/d; /^$/d; s@/@\\\/@g; s/'//g; s/\"//g; s/\[/\\\[/g; s/\]/\\\]/g" "$1" | grep "^.*=.*$")) || return 7

	# create the find/replace argument in one
	# line instead of invoking sed every loop
	for i in ${LIBCONFIG_OLD[@]}; do
		LIBCONFIG_CMD+=("-e s/^${i/=*/=}.*$/${i}/g")
	done

	# invoke sed once, with the long argument we just created
	LIBCONFIG_CMD=(sed "${LIBCONFIG_CMD[@]}" "$2")
	"${LIBCONFIG_CMD[@]}"
}

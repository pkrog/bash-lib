# The name/prefix of this module is TF (TestThat):
#   "tf_"  for the public functions.
#   "TF_"  for the public global variables or constants.
#   "_tf_" for the private functions.
#   "_TF_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_TF_SOURCED ]] || return 0
	_TF_SOURCED=1
fi

function tf_get_nb_rows {

	local file=$1
	local header=$2

	n=$(wc -l <$1)

 	# Deduct header line
	if [[ -n $header && $header -ne 0 ]] ; then
		((n=n-1))
	fi

	echo $n
}

function tf_csv_get_col_index {

	local file=$1
	local sep=$2
	local col_name=$3

	n=$(head -n 1 "$file" | tr "$sep" "\n" | egrep -n "^\"?${col_name}\"?\$" | sed 's/:.*$//')

	if [[ -z $n ]] ; then
		n=-1
	fi

	echo $n
}

function tf_csv_count_values {

	local file=$1
	local sep=$2
	local col=$3

	col_index=$(tf_csv_get_col_index $file $sep $col)
	[[ $col_index -gt 0 ]] || return 1
	nb_values=$(awk "BEGIN{FS=\"$sep\"}{if (NR > 1 && \$$col_index != \"NA\") {++n}} END{print n}" $file)

	echo $nb_values
}

function tf_csv_get_nb_cols {

	local file=$1
	local sep=$2

	echo $(head -n 1 "$file" | tr "$sep" "\n" | wc -l)
}

function tf_csv_get_col_names {

	local file=$1
	local sep=$2
	local ncol=$3
	local remove_quotes=$4
	local cols=

	if [[ -z $ncol || $ncol -le 0 ]] ; then
		cols=$(head -n 1 "$file")
	else
		cols=$(head -n 1 "$file" | tr "$sep" "\n" | head -n $ncol | tr "\n" "$sep")
	fi

	# Remove quotes
	if [[ $remove_quotes -eq 1 ]] ; then
		cols=$(echo $cols | sed 's/"//g')
	fi

	echo $cols
}

function tf_csv_get_val {

	local file=$1
	local sep=$2
	local col=$3
	local row=$4

	col_index=$(tf_csv_get_col_index $file $sep $col)
	[[ $col_index -gt 0 ]] || return 1
	val=$(awk 'BEGIN{FS="'$sep'"}{ if (NR == '$row' + 1) {print $'$col_index'} }' $file)

	echo $val
}


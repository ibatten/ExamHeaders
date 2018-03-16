#!/bin/ksh

# this script is mostly for fun: there's a perl version which is much
# more sensible

thetag=$1
titles=$2
db=codes.db

if [[ ! -n $thetag || ! -s $titles || ! -s $db ]]; then
    echo $0: arguments should be tag titlefile database 1>&2
    exit 1
fi


print_info() {
    echo print_info on $1 1>&2
    
    count=$(sqlite3 \
		-cmd "select count(rowid) from modules where name='$1' or fullname='$1'" $db < /dev/null)

    if [[ $count != 1 ]]; then
	echo $count rows for $1 when there should be 1 1>&2
	exit 1
    fi

    ( set -o noglob
      cat <<\ZZZ
changequote(`[[',`]]')dnl
ZZZ
      echo "select * from modules where name = '$1' or fullname = '$1' limit 1" |
	  sqlite3 -line $db | while read var equals val; do
	    if [[ $equals != = ]]; then
		echo "line $var $equals $val from sql is not var = val" 1>&2
		exit 1
	    fi
	    printf 'define([[_%s]],[[%s]])dnl\n' "$var" "$val" 
	 done
      cat <<\ZZZ
\ModuleName{_fullname}
\Duration{_duration}
\BannerCode{_banner}
\ifthenelse{\equal{\TheResit}{Y}}{
\ACode{_resitacode}
\Date{Resit August Examinations _year}
}{
\ACode{_acode}
\Date{Main May/June Examinations _year}
}
ZZZ
    ) | m4 -D_year=$(date +%Y)
}

print_extended_info() {
    echo '\ifthenelse{\boolean{extended}}{'
    print_info "$2"
    echo '}{'
    print_info "$1"
    echo '}'
}
    

while IFS='|' read tag nonextended extended; do
    if [[ -z $tag ]]; then
	echo no tag on $tag $nonextended $extended 1>&2
	continue
    fi

    [[ $tag = $thetag ]] || continue
    
    if [[ -n $nonextended && -n $extended ]]; then
	print_extended_info "$nonextended" "$extended" > ${tag}_codes.tex
    elif [[ -n $nonextended ]]; then
	print_info "$nonextended" > ${tag}_codes.tex
    else
	echo confused about $tag $nonextended $extended
	exit 1
    fi

    if grep _ ${tag}_codes.tex; then
	echo ${tag}_codes.tex appears to contain unresolved variables 1>&2
	exit 1
    fi

done < $titles


	

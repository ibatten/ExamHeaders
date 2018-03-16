#!/bin/ksh

sql=/tmp/$(basename $0).sql.$$
trap "rm -f $sql" 0

file=$1
db=$2

if [[ -z $file || -z $db ]]; then
    echo no file or no db 1>&2
    exit 1
fi


cat > $sql <<\ZZZ
 drop table if exists modules;
 create table modules (name text, fullname text, banner text, acode text,
     resitacode text, duration text);
 begin transaction;    
ZZZ


while IFS=, read tag banner level name acode resitacode owner fullname duration rest; do
    error=''
    [[ $tag = COMP ]] || continue
    [[ $banner =~ ^06\ [0-9]+$ ]] || error="$error banner $banner "
    [[ $level =~ ^L[CIHMF]$ ]] || error="$error level $level "
    [[ -n $name ]] || error="$error name $name "
    [[ $acode =~ ^A[0-9]*$ ]] || error="$error acode $acode "
    [[ $resitacode =~ ^(A[0-9])|$ ]] || error="$error resitacode $resitacode "
    [[ $resitacode =~ ^\ *$ ]] && resitacode='no resitacode available'
    [[ -n $owner ]] || error="$error owner $owner "
    [[ -n $fullname ]] || error="$error fullname $fullname "
    [[ $duration =~ ^0[0123]:[0-5][0-9]$ ]] || error="$error duration $duration "

    if [[ -z $error ]]; then
	cat 1>&3 <<ZZZ
 insert or replace into modules values ("$name", "$fullname","$banner","$acode",
 "$resitacode", "$duration");
ZZZ
    else
	echo $banner $error 1>&2
    fi
done < $file 3>> $sql

echo 'COMMIT;' >> $sql

sqlite3 $db < $sql

echo checking for duplicate module names:
sqlite3 $db <<\ZZZ
select name,fullname,count(banner) from modules
   group by name having count(banner)!=1;
ZZZ


# Local Variables:
# mode: shell-script
# End:

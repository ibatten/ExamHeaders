#!/bin/ksh

sql=/tmp/sql.$$
trap "rm -f $sql" 0

codedb=$1
titles=$2

if [[ ! -s $codedb || ! -s $titles ]]; then
    echo usage $0: codedb.db titles 1>&2
    exit 1
fi

while IFS='|' read tag nonextended extended; do
    if [[ -z $tag ]]; then
	echo no tag on $tag $nonextended $extended 1>&2
	continue
    fi
    extag=${tag}_extended

    cat > $sql <<EOF
select printf('cp -p %s.pdf %s_question_main_%s_Printing.pdf', 
  "$tag",acode,"$tag") 
  from modules 
  where name="$nonextended" and acode like "A%";
select printf('cp -p %s_resit.pdf %s_question_resit_%s_Printing.pdf', 
  "$tag",resitacode,"$tag") 
  from modules 
  where name="$nonextended" and resitacode like "A%";
select printf('cp -p %s.pdf %s_question_main_%s_Printing.pdf', 
  "$extag",acode,"$extag") 
  from modules 
  where name="$extended" and acode like "A%";
select printf('cp -p %s_resit.pdf %s_question_resit_%s_Printing.pdf', 
  "$extag",resitacode,"$extag") 
  from modules 
  where name="$extended" and resitacode like "A%";

EOF
    sqlite3 $codedb < $sql 
done < $titles
    





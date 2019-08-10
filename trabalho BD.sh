#!/bin/bash

###### HELPs
# Comando pra dar append em conteúdo em file
# sed '<linha>s/$/<conteudoPraAppendar>/' <arquivo> -i
# sed '1s/$/:e/' file -i

# Comando pra remover ultimo char de uma dada linha em file
# sed <linha.s'/.$//' <arquivo>
# sed 1s'/.$//' file

# Comando pra mudar toda uma linha que achar um result
# sed -i '/<dataToFindToReplace>/c\<textToBeAddeded>' /file
# sed -i '/TEXT_TO_BE_REPLACED/c\This line is removed by the admin.' /tmp/foo


### Variables set#######################
if ! [[ -d ~/.dbconfigs ]]; then
    mkdir ~/.dbconfigs
fi



update-vars() {
    CONF="/home/$USER/.dbconfigs";
    if ! [[ -e $CONF/dir && -e $CONF/db ]]; then
        touch "$CONF/dir";
        touch "$CONF/db";
        DIR="";DB="";
    else
        DIR=$(cat "$CONF/dir");
        DB=$(cat "$CONF/db");
        ((COLUMNS=1+$(head -2 "$DIR/$DB" | tail -1 | grep -o ':' | wc -l) )) 2> /dev/null;
    fi
}
##########################################################

update-vars;

echo "";

banner() {
    echo -e "Seja bem-vindo ao emulador de Banco de Dados 0.01,\nprovido até você por AJ Group LTDA";
}


add-entry() {
    echo "add-entry";
}

define-directory() {
    if  ! [[ -d $@ ]]; then
        echo "Criando diretório $@";
        mkdir "$@";
        cd "$@" || exit; cwd=$(pwd 2> /dev/null); cd - || exit > /dev/null;
        echo "$cwd" 1> "$CONF/dir"; update-vars;
        echo -e "#dbfile\n" > "$DIR/database"; echo "database" > $CONF/db; update-vars;
    fi
}

define-database() {
    if ! [[ -e $DIR/database ]]; then
        touch "$DIR/$@"; echo -e "#dbfile\n" > "$DIR/$@";
    else
        mv "$DIR/database" "$DIR/$@"; echo "$@" > "$CONF/db"; update-vars;
    fi
}

define-structure() {
    read -r -p "Defining the structure will delete all data from the BD. Are you sure you want to proceed? [N/y] " answer;
    if ! [[ "$answer" == y || "$answer" == Y ]]; then
        exit 0;
    fi
    
    head -2 "$DIR/$DB" > /tmp/tmpdbfile;
    cat /tmp/tmpdbfile > "$DIR/$DB";
    
    sed 2s'/^.*$//' "$DIR/$DB" -i;
    for argument in "$@"
    do
        sed "2s/$/$argument:/" "$DIR/$DB" -i;
    done;
    sed 2s'/.$//' "$DIR/$DB" -i;
    echo "Structure created succesfully.";
    update-vars;
}

add-columns() {
    for argument in "$@"
    do
        sed "2s/$/:$argument:/" "$DIR/$DB" -i;
    done;
    sed 2s'/.$//' "$DIR/$DB" -i;
    update-vars;
}

add-data() {
    actualData="$@";
    hash=$(echo -n "$actualData" | md5sum | cut -c1-9 | tr -d '\n');
    if [[ "$(cat "$DIR/$DB" | grep "$hash")" ]]; then
        echo "[Error] Data already in database."; exit 1;
    fi
    count=1;
    if ! [[ "$#" == "$(($COLUMNS-1))" ]]; then
        echo "[Error] Wrong amount of data: $#, it should be $(($COLUMNS-1))"; exit 1;
    fi
    
    for data in "$@"
    do
        size=$(echo "$data" | wc -c)
        if [[ "$count" == 1 ]]; then
            if [[ "$size" -gt 50 ]]; then
                echo "[Error] tad1 should be lesser than 50 bytes. Actually: $size."; exit 1;
            fi
            elif [[ "$count" == 2 ]]; then
            if [[ "$size" -gt 30 ]]; then
                echo "[Error] tad2 should be lesser than 30 bytes. Actually: $size."; exit 1;
            fi
        fi
        ((count++));
    done
    echo "" >> "$DIR/$DB";
    for data in "$@"
    do
        echo -n "$data:" >> "$DIR/$DB";
    done
    echo -n "$hash" >> "$DIR/$DB";
    #sed '$ s/:$//' "$DIR/$DB" -i;
}

view-database() {
    tail --lines=+2 "$DIR/$DB" | tr ':' ',';
}

remove-data() {
    appear=$(cat -n "$DIR/$DB" | grep "$@" | cut -f1;);
    sed -e "$appear d" "$DIR/$DB" -i;
}

search-data() {
    cat -n "$DIR/$DB" | grep "$@"
}

change-data() {
    if ! [[ $(tail --lines=+3 "$DIR/$DB" | cut -d: -f3 | grep "$1") ]]; then
        echo "[Error] Hash not found";
    fi
    hash=$(echo -n "$2$3" | md5sum | cut -c1-9 | tr -d '\n');
    sed -i "/$1/c$2:$3:$hash" "$DIR/$DB";
}

#Testes condicionais de flags, acerca do uso do programa
if [ "$*" == "-h" ] || [ "$*" == "--help" ] || [ "$*" == "" ];
then
    help;
else
    case "$1" in
        -a | --add-entry       ) shift; add-entry ; shift $#;                   ;;
        -d | --define-directory ) shift; define-directory "$@"; shift $#;       ;;
        -dd | --define-database ) shift; define-database "$@"; shift $#;        ;;
        -ds | --define-structure ) shift; define-structure "$@"; shift $#;      ;;
        -ac | --add-columns     ) shift; add-columns "$@"; shift $#;            ;;
        -vd | --view-database   ) shift; view-database; shift $#;               ;;
        -ad | --add-data        ) shift; add-data "$@"; shift $#;               ;;
        -rd | --remove-data     ) shift; remove-data "$@"; shift $#;            ;;
        -sd | --search-data     ) shift; search-data "$@"; shift $#;            ;;
        -cd | --change-data     ) shift; change-data "$@"; shift $#;            ;;
        *                     ) echo "Uknown Flag, exiting..."; exit 1;                                  ;;
    esac
fi
{
        if($2=="INSERT") {
            table=$4;count=0;
        }
        else if($2=="UPDATE") {
            table=$3;count=0;
        }
        else if($2~"@1="&&count==0&&$2!~"@1=\047") {
            if(table in tables) {
                tables[table]=tables[table]",";
            }
            tables[table]=tables[table]
            substr($2,4);count=1;
        }
    }
    END {
        for (key in tables) {
            print key": "tables[key]
        }
}

#!/bin/bash

set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# crea cartelle di lavoro
mkdir -p "$folder"/regionali/rawdata
mkdir -p "$folder"/regionali/rawdata/scrutini
mkdir -p "$folder"/regionali/processing
mkdir -p "$folder"/regionali/processing/scrutini
mkdir -p "$folder"/regionali/output
mkdir -p "$folder"/regionali/resources

# svuota cartella dati grezzi
rm "$folder"/regionali/rawdata/*

# scarica anagrafica ripartizioni territoriali

curl 'https://elezioni.interno.gov.it/assets/enti/20200920/regionali_territoriale_italia.json' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'Referer: https://elezioni.interno.gov.it/regionali/scrutini/20200920/elenchiRI' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
  --compressed | jq . >"$folder"/regionali/resources/ita.json

jq <"$folder"/regionali/resources/ita.json '.enti' | mlr --j2t unsparsify then filter '$tipo=="PR"' then cut -f cod,desc then put -S '$RE=sub($cod,"^([0-9]{2})(.+)$","\1");$CR=sub($cod,"^([0-9]{2})([0-9]{3})(.+)$","\2")' | tail -n +2 >"$folder"/regionali/rawdata/itaCR.tsv

jq <"$folder"/regionali/resources/ita.json '.enti' | mlr --j2t unsparsify then filter '$tipo=="CM"' then cut -f cod,desc then put -S '$RE=sub($cod,"^([0-9]{2})(.+)$","\1");$CR=sub($cod,"^([0-9]{2})([0-9]{3})(.+)$","\2");$CM=sub($cod,"^(.+)([0-9]{4})$","\2")' | tail -n +2 >"$folder"/regionali/rawdata/itaCM.tsv

# esegui il loop, scarica dati grezzi in format JSON e produci JSON
while IFS=$'\t' read -r cod desc RE CR CM; do
  curl 'https://eleapi.interno.gov.it/siel/PX/scrutiniR/DE/20200920/TE/07/RE/'"$RE"'/PR/'"$CR"'/CM/'"$CM"'' \
    -H 'Connection: keep-alive' \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
    -H 'Content-Type: application/json' \
    -H 'Origin: https://elezioni.interno.gov.it' \
    -H 'Sec-Fetch-Site: same-site' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Sec-Fetch-Dest: empty' \
    -H 'Referer: https://elezioni.interno.gov.it/regionali/scrutini/20200920/scrutiniRI'"$cod"'' \
    -H 'Accept-Language: en-US,en;q=0.9,it;q=0.8' \
    --compressed | jq . >"$folder"/regionali/rawdata/scrutini/"$cod".json
done <"$folder"/regionali/rawdata/itaCM.tsv

# estrai dai JSON i CSV su comuni, candidati e liste
for i in "$folder"/regionali/rawdata/scrutini/*.json; do
  cod=$(echo "$i" | sed -r 's/^(.+\/)([0-9]+)(\..+)$/\2/g')
  #echo "$cod"
  jq <"$i" '.cand' | mlr --j2c unsparsify then cut -x -r -f "liste:" then put -S '$comune="'"$cod"'"' then reorder -f comune >"$folder"/regionali/processing/scrutini/candidati_"$cod".csv
  jq <"$i" '.int' | mlr --j2c unsparsify then put -S '$comune="'"$cod"'"' then reorder -f comune >"$folder"/regionali/processing/scrutini/int_"$cod".csv
  jq <"$i" '[.cand|.[]|select(.liste[0].pos != null)|{posC:.pos,liste}]' | mlr --j2c unsparsify then reshape -r "liste:" -o item,value then filter -x '$value==""' then put '$ln=regextract($item,"[0-9]+");$item=sub($item,".+:","")' then reorder -f posC,ln then reshape -s item,value then put -S '$comune="'"$cod"'"' then reorder -f comune >"$folder"/regionali/processing/scrutini/liste_"$cod".csv
done

# unici i CSV per tipo
mlr --csv unsparsify "$folder"/regionali/processing/scrutini/int_*.csv >"$folder"/regionali/output/comuni.csv
mlr --csv unsparsify "$folder"/regionali/processing/scrutini/candidati_*.csv >"$folder"/regionali/output/candidati.csv
mlr --csv unsparsify "$folder"/regionali/processing/scrutini/liste_*.csv >"$folder"/regionali/output/liste.csv

# imposta come decimale il punto e non la virgola
mlr -I --csv put -S '$perc_vot=sub($perc_vot,",",".")' then rename comune,codINT "$folder"/regionali/output/comuni.csv
mlr -I --csv put -S '$perc_lis=sub($perc_lis,",",".");$perc=sub($perc,",",".")' then rename pos,posC,comune,codINT "$folder"/regionali/output/candidati.csv
mlr -I --csv put -S '$perc=sub($perc,",",".")' then rename comune,codINT "$folder"/regionali/output/liste.csv

# prepara file per JOIN tra dati regionali dei comuni e anagrafica elettorale ed esegui JOIN
mlr --t2c cut -f "CODICE ISTAT",codINT "$folder"/referendum/resources/anagraficaComuni.tsv >"$folder"/regionali/processing/tmp.csv
mlr -I --csv put -S '$codINT=sub($codINT,"^([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{3})$","\1\3\4")' "$folder"/regionali/output/comuni.csv
mlr --csv join --ul -j codINT -f "$folder"/regionali/output/comuni.csv then unsparsify "$folder"/regionali/processing/tmp.csv >"$folder"/regionali/processing/tmp2.csv
mlr --csv cut -x -f codINT "$folder"/regionali/processing/tmp2.csv >"$folder"/regionali/output/comuni.csv

# sposta campo codice ISTAT all'inizio
mlr -I --csv reorder -f "CODICE ISTAT" "$folder"/regionali/output/candidati.csv

# prepara file per JOIN tra dati regionali dei candidati e anagrafica elettorale ed esegui JOIN
mlr --t2c cut -f "CODICE ISTAT",codINT "$folder"/referendum/resources/anagraficaComuni.tsv >"$folder"/regionali/processing/tmp.csv
mlr -I --csv put -S '$codINT=sub($codINT,"^([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{3})$","\1\3\4")' "$folder"/regionali/output/candidati.csv
mlr --csv join --ul -j codINT -f "$folder"/regionali/output/candidati.csv then unsparsify "$folder"/regionali/processing/tmp.csv >"$folder"/regionali/processing/tmp2.csv
mlr --csv cut -x -f codINT "$folder"/regionali/processing/tmp2.csv >"$folder"/regionali/output/candidati.csv

# sposta campo codice ISTAT all'inizio
mlr -I --csv reorder -f "CODICE ISTAT" "$folder"/regionali/output/liste.csv

# prepara file per JOIN tra dati regionali delle liste e anagrafica elettorale ed esegui JOIN
mlr --t2c cut -f "CODICE ISTAT",codINT "$folder"/referendum/resources/anagraficaComuni.tsv >"$folder"/regionali/processing/tmp.csv
mlr -I --csv put -S '$codINT=sub($codINT,"^([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{3})$","\1\3\4")' "$folder"/regionali/output/liste.csv
mlr --csv join --ul -j codINT -f "$folder"/regionali/output/liste.csv then unsparsify "$folder"/regionali/processing/tmp.csv >"$folder"/regionali/processing/tmp2.csv
mlr --csv cut -x -f codINT "$folder"/regionali/processing/tmp2.csv >"$folder"/regionali/output/liste.csv

# sposta campo codice ISTAT all'inizio
mlr -I --csv reorder -f "CODICE ISTAT" "$folder"/regionali/output/liste.csv

# rinomina file
for i in comuni candidati liste; do
  mv "$folder"/regionali/output/"$i".csv "$folder"/regionali/output/scrutini_"$i".csv
done

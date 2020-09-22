#!/bin/bash

### requisiti ###
# miller https://github.com/johnkerl/miller
# gnu parallel https://www.gnu.org/software/parallel/
# jq https://stedolan.github.io/jq/
### requisiti ###

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# crea cartelle di lavoro
mkdir -p "$folder"/referendum/rawdata/scrutini
mkdir -p "$folder"/referendum/processing/scrutini
mkdir -p "$folder"/referendum/resources

# svuota cartella dati grezzi
rm "$folder"/referendum/rawdata/scrutini/*
rm "$folder"/referendum/processing/scrutini/*

# scarica anagrafica ripartizioni territoriali

jq <"$folder"/referendum/resources/ita.json '.enti' | mlr --j2t unsparsify then filter '$tipo=="CM"' then cut -f cod,desc then put -S '$RE=sub($cod,"^([0-9]{2})(.+)$","\1");$PR=sub($cod,"^([0-9]{2})([0-9]{3})(.+)$","\2");$CM=sub($cod,"^(.+)([0-9]{4})$","\2")' | tail -n +2 >"$folder"/referendum/resources/itaCM.tsv

# scarica in parallelo i dati sui comuni
parallel --colsep "\t" --max-args 1 -j50% 'curl -k -L --max-time 1200 --connect-timeout 1200 "https://eleapi.interno.gov.it/siel/PX/scrutiniFI/DE/20200920/TE/09/SK/01/RE/{3}/PR/{4}/CM/{5}" \
-H "Connection: keep-alive" \
-H "Accept: application/json, text/javascript, */*; q=0.01" \
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) #Chrome/85.0.4183.102 Safari/537.36" \
-H "Content-Type: application/json" \
-H "Origin: https://elezioni.interno.gov.it" \
-H "Sec-Fetch-Site: same-site" \
-H "Sec-Fetch-Mode: cors" \
-H "Sec-Fetch-Dest: empty" \
-H "Referer: https://elezioni.interno.gov.it/referendum/scrutini/20200920/scrutiniFI01{1}" \
-H "Accept-Language: en-US,en;q=0.9,it;q=0.8" --compressed >./referendum/rawdata/scrutini/{1}.json 2>/dev/null' :::: ./referendum/resources/itaCM.tsv

# converti in CSV i dati
for i in "$folder"/referendum/rawdata/scrutini/*.json; do
  #crea una variabile da usare per estrarre nome e estensione
  filename=$(basename "$i")
  #estrai estensione
  extension="${filename##*.}"
  #estrai nome file
  filename="${filename%.*}"
  mlr --j2c unsparsify then put '$comune=FILENAME;$comune=sub($comune,".+/","");$comune=regextract($comune,"[0-9]+")' then reorder -f comune "$i" >"$folder"/referendum/processing/scrutini/"$filename".csv
done

# fai il merge dei file CSV
mlr --csv unsparsify "$folder"/referendum/processing/scrutini/*.csv >"$folder"/referendum/output/scrutiniComuni.csv

# estrai campi utili e rinominali
mlr -I --csv unsparsify then cut -o -f "nome","comune","int:cod_reg","int:desc_com","int:desc_prov","int:desc_reg","int:ele_f","int:ele_m","int:ele_t","int:sz_tot","scheda:0:dt_agg","scheda:0:perc_no","scheda:0:perc_si","scheda:0:perc_vot","scheda:0:sk_bianche","scheda:0:sk_contestate","scheda:0:sk_nulle","scheda:0:sz_perv","scheda:0:vot_f","scheda:0:vot_m","scheda:0:vot_t","scheda:0:voti_no","scheda:0:voti_si" then rename "comune","codINT","int:cod_reg","cod_reg","int:desc_com","desc_com","int:desc_prov","desc_prov","int:desc_reg","desc_reg","int:ele_f","elettrici_femmine","int:ele_m","elettori_maschi","int:ele_t","elettori_totali","int:sz_tot","sezioni_totali","scheda:0:dt_agg","dataAggiornamentoDati","scheda:0:perc_no","percentuale_no","scheda:0:perc_si","percentuale_si","scheda:0:perc_vot","percentuale_votanti","scheda:0:sk_bianche","schede_bianche","scheda:0:sk_contestate","schede_contestate","scheda:0:sk_nulle","schede_nulle","scheda:0:sz_perv","sezioni_pervenute","scheda:0:vot_f","votanti_femmine","scheda:0:vot_m","votatanti_maschi","scheda:0:vot_t","votanti_totali","scheda:0:voti_no","voti_no","scheda:0:voti_si","voti_si" "$folder"/referendum/output/scrutiniComuni.csv

# prepara file per JOIN tra dati referendum e anagrafica elettorale ed esegui JOIN
mlr --t2c cut -f "CODICE ISTAT",codINT "$folder"/referendum/resources/anagraficaComuni.tsv >"$folder"/referendum/processing/tmp.csv
mlr --csv join --ul -j codINT -f "$folder"/referendum/output/scrutiniComuni.csv then unsparsify "$folder"/referendum/processing/tmp.csv >"$folder"/referendum/processing/tmp2.csv
mlr --csv cut -x -f codINT "$folder"/referendum/processing/tmp2.csv >"$folder"/referendum/output/scrutiniComuni.csv

# sposta campo codice ISTAT all'inizio
mlr -I --csv reorder -f "CODICE ISTAT" "$folder"/referendum/output/scrutiniComuni.csv

# sostituisci la virgola con il punto
mlr -I --csv put -S 'for (k in $*) {$[k] = sub($[k], ",", ".");}' "$folder"/referendum/output/scrutiniComuni.csv

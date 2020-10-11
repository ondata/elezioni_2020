#!/bin/bash

set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# crea cartelle di lavoro
mkdir -p "$folder"/rawdata
mkdir -p "$folder"/processing
mkdir -p "$folder"/resources

# scarica dati di base

mlr --c2n cut -f value "$folder"/resources/listaComuni.csv >"$folder"/processing/tmpLista

# scarica dati liste
download="no"

if [[ "$download" == "yes" ]]; then
  while IFS=$'\t' read -r id; do
    curl -kL "https://dati.elezioni.marche.it/static_json/liste_0_$id.json" | jq . >"$folder"/rawdata/liste_0_"$id".json
  done <"$folder"/processing/tmpLista
fi

### liste ###

# per ogni file delle liste, quindi per ogni comune, estrai i vari oggetti contenuti nel JSON
for i in {1..228}; do

  # anagrCandidati

  jq <"$folder"/rawdata/liste_0_"$i".json '.anagrCandidati' | mlr --j2c unsparsify then reshape -r '[:]' -o item,value then filter -S '$value=~".+"' then nest --explode --values --across-fields --nested-fs ":" -f item then label listaDelete,candidatoDelete,item,value then reshape -s item,value then cut -x -r -f "Delete" then put -S '$idComune="'"$i"'"' >"$folder"/rawdata/liste_0_"$i"-anagrCandidati.csv

  # totSezioni

  jq <"$folder"/rawdata/liste_0_"$i".json '.totSezioni' | mlr --j2c unsparsify then put -S '$idComune="'"$i"'"' >"$folder"/rawdata/liste_0_"$i"-totSezioni.csv

  # votiCandidati

  jq <"$folder"/rawdata/liste_0_"$i".json '.votiCandidati[]' | mlr --j2c unsparsify then reshape -r '[:]' -o item,value then filter -S '$value=~".+"' then cut -x -f item,value then put -S '$idComune="1"' >"$folder"/rawdata/liste_0_"$i"-votiCandidati.csv

  jq <"$folder"/rawdata/liste_0_"$i".json '.votiCandidati[].arrVotiCandidato' | mlr --j2c unsparsify then cat -n then reshape -r '[:]' -o item,value then filter -S '$value=~".+"' then nest --explode --values --across-fields --nested-fs ":" -f item then reshape -s item_2,value then rename item_1,id then put -S '$idComune="'"$i"'"' >"$folder"/rawdata/liste_0_"$i"-votiCandidati-arrVotiCandidato.csv

  # votiListe

  jq <"$folder"/rawdata/liste_0_"$i".json '.votiListe' | mlr --j2c unsparsify then cut -x -r -f ":" then put -S '$idComune="'"$i"'"' >"$folder"/rawdata/liste_0_"$i"-votiListe.csv

  jq <"$folder"/rawdata/liste_0_"$i".json '.votiListe.arrVotiListe' | mlr --j2c unsparsify then reshape -r '[:]' -o item,value then filter -S '$value=~".+"' then nest --explode --values --across-fields --nested-fs ":" -f item then reshape -s item_2,value then rename item_1,id then put -S '$idComune="'"$i"'"' >"$folder"/rawdata/liste_0_"$i"-votiListe-arrVotiListe.csv

  # anagrListe

  jq <"$folder"/rawdata/liste_0_"$i".json '.anagrListe' | mlr --j2c unsparsify then put -S '$idComune="'"$i"'"' >"$folder"/rawdata/liste_0_"$i"-anagrListe.csv

done

# unisci per tipo di file, i CSV estratti per ogni comune
mlr --csv cat "$folder"/rawdata/liste_0_*-anagrCandidati.csv >"$folder"/processing/anagrCandidati.csv

mlr --csv cat "$folder"/rawdata/liste_0_*-totSezioni.csv >"$folder"/processing/totSezioni.csv

mlr --csv cat "$folder"/rawdata/liste_0_*-votiCandidati.csv >"$folder"/processing/votiCandidati.csv

mlr --csv cat "$folder"/rawdata/liste_0_*-votiCandidati-arrVotiCandidato.csv >"$folder"/processing/votiCandidati-arrVotiCandidato.csv

mlr --csv cat "$folder"/rawdata/liste_0_*-votiListe.csv >"$folder"/processing/votiListe.csv

mlr --csv cat "$folder"/rawdata/liste_0_*-votiListe-arrVotiListe.csv >"$folder"/processing/votiListe-arrVotiListe.csv

mlr --csv cat "$folder"/rawdata/liste_0_*-anagrListe.csv >"$folder"/processing/anagrListe.csv

# vedi issue #3

for i in {1..228}; do
  curl -kL "https://dati.elezioni.marche.it/static_json/raggrup_0_$i.json" | jq . >"$folder"/rawdata/raggrup_0_"$i".json
done

jq <"$folder"/rawdata/raggrup_0_100.json '.anagrRaggrup' | mlr --j2c unsparsify then cut -x -r -f ":" then cat -n >"$folder"/processing/anagrRaggrup.csv

for i in {1..228}; do
  jq <"$folder"/rawdata/raggrup_0_"$i".json '.votiRaggrup.arrVotiRaggrup' | mlr --j2c unsparsify then reshape -r '[:]' -o item,value then filter -S '$value=~".+"' then nest --explode --values --across-fields --nested-fs ":" -f item then rename item_1,id then reshape -s item_2,value then put -S '$idComune="'"$i"'"' >"$folder"/rawdata/raggrup_0_"$i"-votiRaggrup-arrVotiRaggrup.csv
done

mlr --csv cat "$folder"/rawdata/raggrup_0_*-votiRaggrup-arrVotiRaggrup.csv >"$folder"/processing/votiRaggrup-arrVotiRaggrup.csv

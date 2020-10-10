#!/bin/bash

set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# crea cartelle di lavoro
mkdir -p "$folder"/rawdata
mkdir -p "$folder"/processing
mkdir -p "$folder"/resources

### liste ###

curl "https://dati.elezioni.marche.it/static_json/liste_0_1.json" | jq . >"$folder"/rawdata/liste.json

# anagrCandidati

jq <"$folder"/rawdata/liste.json '.anagrCandidati' | mlr --j2c unsparsify then reshape -r '[:]' -o item,value then filter -S '$value=~".+"' then nest --explode --values --across-fields --nested-fs ":" -f item then label listaDelete,candidatoDelete,item,value then reshape -s item,value then cut -x -r -f "Delete" >"$folder"/rawdata/liste_0_1-anagrCandidati.csv

# totSezioni

jq <"$folder"/rawdata/liste.json '.totSezioni' | mlr --j2c unsparsify >"$folder"/rawdata/liste_0_1-totSezioni.csv

# votiCandidati

jq <"$folder"/rawdata/liste.json '.votiCandidati[]' | mlr --j2c unsparsify then reshape -r '[:]' -o item,value then filter -S '$value=~".+"' then cut -x -f item,value >"$folder"/rawdata/liste_0_1-votiCandidati.csv

jq <"$folder"/rawdata/liste.json '.votiCandidati[].arrVotiCandidato' | mlr --j2c unsparsify then cat -n then reshape -r '[:]' -o item,value then filter -S '$value=~".+"' then nest --explode --values --across-fields --nested-fs ":" -f item then reshape -s item_2,value then rename item_1,id >"$folder"/rawdata/liste_0_1-votiCandidati-arrVotiCandidato.csv

# votiListe

jq <"$folder"/rawdata/liste.json '.votiListe' | mlr --j2c unsparsify then cut -x -r -f ":" >"$folder"/rawdata/liste_0_1-votiListe.csv

jq <"$folder"/rawdata/liste.json '.votiListe.arrVotiListe' | mlr --j2c unsparsify then reshape -r '[:]' -o item,value then filter -S '$value=~".+"' then nest --explode --values --across-fields --nested-fs ":" -f item then reshape -s item_2,value then rename item_1,id >"$folder"/rawdata/liste_0_1-votiListe-arrVotiListe.csv

# anagrListe

jq <"$folder"/rawdata/liste.json '.anagrListe' | mlr --j2c unsparsify >"$folder"/rawdata/liste_0_1-anagrListe.csv

#!/bin/bash

#set -x

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# crea cartelle di lavoro
mkdir -p "$folder"/referendum/rawdata
mkdir -p "$folder"/referendum/output
mkdir -p "$folder"/referendum/processing

# svuota cartella dati grezzi
rm "$folder"/referendum/rawdata/*.json
rm "$folder"/referendum/processing/*.csv

# URL_check
URL="https://eleapi.interno.gov.it/siel/PX/votantiFI/DE/20200920/TE/09/SK/01"

code=$(curl -s -L -o /dev/null -w "%{http_code}" \
  -H 'Connection: keep-alive' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://elezioni.interno.gov.it' \
  -H 'Sec-Fetch-Site: same-site' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://elezioni.interno.gov.it/referendum/votanti/20200920/votantiFI01' \
  -H 'Accept-Language: en-US,en;q=0.9,it;q=0.8' \
  -H 'If-Modified-Since: Mon, 21 Sep 2020 16:03:18 GMT' \
  --compressed ''"$URL"'')

# se il sito è raggiungibile scarica i dati
if [ $code -eq 200 ]; then

  ## dati nazionali

  curl -Lks 'https://eleapi.interno.gov.it/siel/PX/votantiFI/DE/20200920/TE/09/SK/01' \
    -H 'Connection: keep-alive' \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
    -H 'Content-Type: application/json' \
    -H 'Origin: https://elezioni.interno.gov.it' \
    -H 'Sec-Fetch-Site: same-site' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Sec-Fetch-Dest: empty' \
    -H 'Referer: https://elezioni.interno.gov.it/referendum/votanti/20200920/votantiFI01' \
    -H 'Accept-Language: en-US,en;q=0.9,it;q=0.8' \
    -H 'If-Modified-Since: Mon, 21 Sep 2020 16:03:18 GMT' \
    --compressed | jq . >"$folder"/referendum/output/datiNazionali.json

  jq <"$folder"/referendum/output/datiNazionali.json '.enti.ente_p' | mlr --j2c unsparsify >"$folder"/referendum/output/affluenzaItalia.csv
  jq <"$folder"/referendum/output/datiNazionali.json '.enti.enti_f' | mlr --j2c unsparsify >"$folder"/referendum/output/affluenzaRegioni.csv

  numeroComuniScrutinati=$(jq <referendum/output/datiNazionali.json '.enti.ente_p.com_vot[3].enti_p')

  # scarica anagrafica ripartizioni territoriali

  curl -Lks 'https://elezioni.interno.gov.it/assets/enti/20200920/referendum_territoriale_italia.json' \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Referer: https://elezioni.interno.gov.it/referendum/votanti/20200920/votantiFI01' \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
    --compressed | jq . >"$folder"/referendum/rawdata/ita.json

  # estrai codici province
  jq <"$folder"/referendum/rawdata/ita.json '.enti' | mlr --j2t unsparsify then filter -S '$tipo=="PR"' then cut -o -f cod,desc then put -S '$PR=sub($cod,"^([0-9]{2})([0-9]{3})(.+)","\2");$altro=sub($cod,"^([0-9]{2})([0-9]{3})(.+)","\1\2")' | tail -n +2 >"$folder"/referendum/rawdata/province.tsv

  # esegui il loop, scarica dati grezzi in format JSON e produci CSV relativo
  while IFS=$'\t' read -r cod desc PR altro; do
    curl -Lks 'https://eleapi.interno.gov.it/siel/PX/votantiFI/DE/20200920/TE/09/SK/01/PR/'"$PR"'' \
      -H 'Connection: keep-alive' \
      -H 'Accept: application/json, text/javascript, */*; q=0.01' \
      -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
      -H 'Content-Type: application/json' \
      -H 'Origin: https://elezioni.interno.gov.it' \
      -H 'Sec-Fetch-Site: same-site' \
      -H 'Sec-Fetch-Mode: cors' \
      -H 'Sec-Fetch-Dest: empty' \
      -H 'Referer: https://elezioni.interno.gov.it/referendum/votanti/20200920/votantiFI01'"$altro"'' \
      -H 'Accept-Language: en-US,en;q=0.9,it;q=0.8' \
      --compressed | jq . >"$folder"/referendum/rawdata/"$altro".json
    jq <"$folder"/referendum/rawdata/"$altro".json '.enti.enti_f[] | . |= .+ {provincia:"'"$cod"'"}' | mlr --j2c unsparsify >"$folder"/referendum/processing/"$altro".csv
  done <"$folder"/referendum/rawdata/province.tsv

  # fai il merge dei CSV in un unico TSV
  mlr --c2t unsparsify "$folder"/referendum/processing/*.csv >"$folder"/referendum/processing/affluenzaComuni.tsv

  # estrai dal TSV i campi utili
  mlr -I --tsv cut -o -f "desc","cod","provincia","ele_t","com_vot:0:dt_com","com_vot:0:perc","com_vot:0:vot_t","com_vot:1:dt_com","com_vot:1:perc","com_vot:1:vot_t","com_vot:2:dt_com","com_vot:2:perc","com_vot:2:vot_t","com_vot:3:dt_com","com_vot:3:perc","com_vot:3:vot_t" "$folder"/referendum/processing/affluenzaComuni.tsv

  # rinomina i campi del TSV
  mlr -I --tsv rename "desc","comune","cod","cod_istat","ele_t","elettori","com_vot:0:dt_com","datah12","com_vot:0:perc","%h12","com_vot:0:vot_t","voti_h12","com_vot:1:dt_com","datah19","com_vot:1:perc","%h19","com_vot:1:vot_t","voti_h19","com_vot:2:dt_com","datah23","com_vot:2:perc","%h23","com_vot:2:vot_t","voti_h23","com_vot:3:dt_com","datah15","com_vot:3:perc","%h15","com_vot:3:vot_t","voti_h15" "$folder"/referendum/processing/affluenzaComuni.tsv

  mlr -I --tsv put '$codINT=fmtnum($cod_istat,"%04d")' then put -S '$codINT=sub($provincia,"0000$","").$codINT' "$folder"/referendum/processing/affluenzaComuni.tsv

  # scarica dati anagrafica elettorale

  URLcodiciComuni="https://dait.interno.gov.it/territorio-e-autonomie-locali/sut/elenco_codici_comuni_csv.php"

  curl -Lks "$URLcodiciComuni" \
    -H 'Connection: keep-alive' \
    -H 'Upgrade-Insecure-Requests: 1' \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
    -H 'Accept-Language: en-US,en;q=0.9,it;q=0.8' \
    -H 'Cookie: has_js=1' \
    --compressed  --insecure >"$folder"/referendum/resources/anagraficaComuni.tsv

  mlr -I --icsvlite -N --otsv --ifs ";" clean-whitespace "$folder"/referendum/resources/anagraficaComuni.tsv
  mlr -I --tsv put -S '${CODICE ISTAT}=gsub(${CODICE ISTAT},"(\"|=)","")' "$folder"/referendum/resources/anagraficaComuni.tsv

  mlr -I --tsv put -S '$codINT=sub(${CODICE ELETTORALE},"^(.{1})(.+)$","\2")' "$folder"/referendum/resources/anagraficaComuni.tsv

  # prepara file per JOIN tra dati referendum e anagrafica elettorale
  mlr --tsv cut -f "CODICE ISTAT",codINT "$folder"/referendum/resources/anagraficaComuni.tsv >"$folder"/referendum/processing/tmp.tsv

  # fai il JOIN
  mlr --tsv join --ul -j codINT -f "$folder"/referendum/processing/affluenzaComuni.tsv then unsparsify then cut -x -f "cod_istat",codINT "$folder"/referendum/processing/tmp.tsv >"$folder"/referendum/processing/tmp2.tsv
  mv "$folder"/referendum/processing/tmp2.tsv "$folder"/referendum/processing/affluenzaComuni.tsv

  mlr -I --tsv reorder -f "CODICE ISTAT" "$folder"/referendum/processing/affluenzaComuni.tsv

  sed -i -r 's/,/\./g' "$folder"/referendum/processing/affluenzaComuni.tsv

  rm "$folder"/referendum/processing/*.csv

  mlr --t2c cat "$folder"/referendum/processing/affluenzaComuni.tsv >"$folder"/referendum/processing/affluenzaComuni.csv

  mlr --csv cat "$folder"/referendum/processing/affluenzaComuni.csv >"$folder"/referendum/output/affluenzaComuni.csv

  # voto all'estero

  curl 'https://eleapi.interno.gov.it/siel/PX/votantiFE/DE/20200920/TE/09/SK/01' \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'Referer: https://elezioni.interno.gov.it/referendum/votanti/20200920/votantiFE01' \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
    -H 'Content-Type: application/json' \
    --compressed | jq . >"$folder"/referendum/output/datiEstero.json

  jq <"$folder"/referendum/output/datiEstero.json '.enti.ente_p' | mlr --j2c unsparsify >"$folder"/referendum/output/affluenzaEstero.csv
  jq <"$folder"/referendum/output/datiEstero.json '.enti.enti_f' | mlr --j2c unsparsify >"$folder"/referendum/output/affluenzaRipartizioni.csv

  mlr --c2n cut -f cod referendum/output/affluenzaRipartizioni.csv |
    while read -r line; do
      curl 'https://eleapi.interno.gov.it/siel/PX/votantiFE/DE/20200920/TE/09/SK/01/ER/0'"$line"'' \
        -H 'Connection: keep-alive' \
        -H 'Accept: application/json, text/javascript, */*; q=0.01' \
        -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
        -H 'Content-Type: application/json' \
        -H 'Origin: https://elezioni.interno.gov.it' \
        -H 'Sec-Fetch-Site: same-site' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Referer: https://elezioni.interno.gov.it/referendum/votanti/20200920/votantiFE01'"$line"'' \
        -H 'Accept-Language: en-US,en;q=0.9' \
        --compressed | jq . >"$folder"/referendum/rawdata/votantiEstero_0"$line".json
      jq <"$folder"/referendum/rawdata/votantiEstero_0"$line".json '.enti.enti_f' | mlr --j2c unsparsify >"$folder"/referendum/rawdata/votantiEstero_0"$line".csv
    done

  mlr --csv unsparsify "$folder"/referendum/rawdata/votantiEstero_0*.csv >"$folder"/referendum/output/datiEstero.csv

fi

# Dati elezioni settembre 2020

**Nota bene**: i dati presenti in questo repository sono riutilizzabili e distribuiti con [Licenza Creative Commons Attribuzione 4.0 Internazionale](https://creativecommons.org/licenses/by/4.0/deed.it).<br>
Se li usi, cita questo repository (https://github.com/ondata/elezioni_2020/) e l'**Associazione onData**.

La **fonte dati** sono le API di Eligendo, che alimentano questo sito <https://elezioni.interno.gov.it/referendum/votanti/20200920/votantiFI01>.

# Referendum

## Affluenza

Il file con le **affluenze** per **comune** è [`affluenzaComuni.csv`](https://github.com/ondata/elezioni_2020/raw/master/referendum/output/affluenzaComuni.csv).

**Nota bene**: al momento non è conteggiato il voto all'estero.

## Scrutini

Il file con gli **scrutini** per **comune** è [`scrutiniComuni.csv`](https://github.com/ondata/elezioni_2020/raw/master/referendum/output/scrutiniComuni.csv).

Nello script per scaricare i dati sugli scrutini è stato usato [GNU Parallel](https://www.gnu.org/software/parallel/).

**Nota bene**:

- al momento non è conteggiato il voto all'estero;
- i dati non sono ancora definitivi, ultimo aggiornamento alle 8:00 del 22 settembre 2020 (fare riferimento alle colonne `sezioni_totali` e `sezioni_pervenute`).

# Regionali

## Scrutini

Sono stati estratti tre file CSV, dei dati sulle 4 elezioni regionali presenti su Eligendo (Campania, Puglia, Veneto e Liguria):

- [`scrutini_comuni.csv`](regionali/output/scrutini_comuni.csv), con i dati di riepilogo per ogni comune;
- [`scrutini_candidati.csv`](regionali/output/scrutini_candidati.csv), con i dati di riepilogo sui candidati;
- [`scrutini_liste.csv`](regionali/output/scrutini_liste.csv), con i dati di riepilogo delle eventuali liste che appoggiano i candidati.

**Nota bene**:

- i dati non sono ancora definitivi, ultimo aggiornamento alle 19:50 del 22 settembre 2020 (per averne contezza, fare riferimento alle colonne `sz_pres`, `sz_cons`, `sz_tot` presenti nel file `scrutini_comuni.csv`).

# Ringraziamenti

Grazie a [Salvatore Fiandaca](https://twitter.com/totofiandaca) per gli stimoli e la collaborazione.

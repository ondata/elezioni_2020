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

**Nota bene**: al momento non è conteggiato il voto all'estero.

# Regionali

## Scrutini

Sono stati estratti tre file CSV, dei dati sulle 4 elezioni regionali presenti su Eligendo (Campania, Puglia, Veneto e Liguria):

- [`scrutini_comuni.csv`](regionali/output/scrutini_comuni.csv), con i dati di riepilogo per ogni comune;
- [`scrutini_candidati.csv`](regionali/output/scrutini_candidati.csv), con i dati di riepilogo sui candidati;
- [`scrutini_liste.csv`](regionali/output/scrutini_liste.csv), con i dati di riepilogo delle eventuali liste che appoggiano i candidati.

## Regione Marche

Su sito del ministero degli Interni, non sono presenti i dati delle elezioni regionali della Regione Marche. <br>
Sul [sito dedicato delle regioni Marche](https://dati.elezioni.marche.it/) è possibile leggerli a video, ma non scaricarli.

Due i passi che hanno portato alla pubblicazione:

- creare uno [script](./regionaliMarche/regionaliMarche.sh), che a partire dalle API che alimenta il sito regionale scaricasse i [dati grezzi](./regionaliMarche/processing);
- ristrutturarli con uno schema simile (non è ad oggi al 100% conforme) a quelli delle altre regione. Di questo si è occupato [Guenter Richter](https://twitter.com/grichter) a cui va il nostro grazie (le sue [mappe dedicate](https://gjrichter.github.io/viz/Elezioni/gallery/Regionali_2020_Marche/)).

Tre file CSV di output:

- [`scrutini_comuni.csv`](regionali/output/scrutini_comuni-marche.csv), con i dati di riepilogo per ogni comune;
- [`scrutini_candidati.csv`](regionali/output/scrutini_candidati-marche.csv), con i dati di riepilogo sui candidati;
- [`scrutini_liste.csv`](regionali/output/scrutini_liste-marche.csv), con i dati di riepilogo delle eventuali liste che appoggiano i candidati.

# Ringraziamenti

Grazie a [Salvatore Fiandaca](https://twitter.com/totofiandaca) per gli stimoli e la collaborazione.

# Chi ha usato questi dati

- "[Mappe sul Referendum](https://twitter.com/Ruffino_Lorenzo/status/1308325183258865664)", di [Lorenzo Ruffino](https://twitter.com/Ruffino_Lorenzo);
- "[Per gli uomini è stato più facile andare a votare?](https://www.instagram.com/p/CFwrnVKFYdl/?igshid=f0wptpkx7bln)", di [Donata Columbro](https://twitter.com/dontyna);
- "[Elezioni regionali 2020 in Puglia](https://gjrichter.github.io/viz/Elezioni/gallery/Regionali_2020_Puglia/)", di [Guenter Richter](https://twitter.com/grichter);
- "[La word cloud dei comuni per numero di votanti al referendum](https://twitter.com/fromAlias/status/1311915787079294976)", di [Fernando Cinquegrani](https://twitter.com/fromAlias).


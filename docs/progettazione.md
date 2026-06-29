# MyProject — Progettazione concettuale

Gestionale per la gestione di cantine e dello stoccaggio di bevande.

---

## 1. Requisiti in linguaggio naturale

Il prodotto proposto è un gestionale software per cantine: si propone come strumento unico per l'archiviazione e la gestione di tutto ciò che riguarda lo stoccaggio delle bevande. L'azienda cliente che utilizza il prodotto ha accesso a un gestionale per le proprie cantine, che tiene conto dei dipendenti che vi lavorano e garantisce la tracciabilità e lo storico delle operazioni svolte sui prodotti.

L'oggetto principale della gestione è lo stoccaggio delle bevande. Di ogni bevanda si considerano la tipologia — vino, birra, analcolico o superalcolico — e la regione di provenienza; nel caso dei vini si registrano inoltre dettagli tecnici specifici, come il vitigno, la vinificazione e l'affinamento.

Il gestionale gestisce infine i movimenti di magazzino: dai movimenti di carico e scarico deriva la quantità disponibile (giacenza) di ogni bevanda. Sono tracciati sia i movimenti interni sia quelli provenienti dall'esterno, come le forniture. Sul fronte della vendita, ogni cantina dispone di una o più carte vini, ciascuna delle quali raccoglie un insieme di bevande messe in listino con i relativi dati di vendita (come il prezzo).

---

## 2. Glossario dei termini

| Termine | Definizione | Sinonimi / da non confondere | Collegamenti | Frequenza |
|---|---|---|---|---|
| Azienda | Cliente del gestionale, solitamente un'azienda | Attività/esercizio (alias); ≠ Produttore e ≠ Fornitore | Cantina | — |
| Cantina | Luogo fisico di stoccaggio dei prodotti | — | Azienda, Carta vini, Dipendente, Movimento, Listino | — |
| Carta vini | Particolare selezione di bevande in vendita, con i relativi dati commerciali | = menù/catalogo; contiene voci di Listino | Cantina, Listino, Dipendente | — |
| Listino | Entità con i dati commerciali di una bevanda in una cantina | Entità a sé (NON attributi di Bevanda); contiene sia prezzo di vendita sia prezzo di acquisto | Carta vini, Bevanda, Cantina | — |
| Dipendente | Utente del gestionale con il potere di modificarlo (operatore) | = utente abilitato alla modifica del gestionale; ≠ cliente/consumatore (che non vi accede) | Cantina, Movimento, Carta vini | — |
| Bevanda | Generico prodotto stoccato e gestito (catalogo globale) | = prodotto; quantità espresse in bottiglie; la giacenza NON è un suo attributo ma del Listino (è relativa alla coppia bevanda-cantina) | Regione, Produttore, Movimento, Listino, Vino, Birra, Analcolico, Superalcolico | — |
| Vino | Bevanda alcolica ottenuta dalla fermentazione dell'uva | — | Bevanda, Vitigno, Vinificazione, Affinamento | — |
| Birra | Bevanda alcolica ottenuta dalla fermentazione di malto e luppolo | — | Bevanda | — |
| Analcolico | Generica bevanda priva di alcol | — | Bevanda | — |
| Superalcolico | Distillato o bevanda oltre i 20 gradi | — | Bevanda | — |
| Vitigno | Varietà di uva da cui si ottiene un vino | = uva / varietà | Vino | — |
| Vinificazione | Processo di trasformazione dell'uva in vino | ≠ Affinamento ≠ invecchiamento (fasi distinte) | Vino | — |
| Affinamento | Fase di maturazione del vino dopo la vinificazione (es. in botte o bottiglia) | ≠ Vinificazione (la precede) | Vino | — |
| Regione | Luogo di provenienza geografica di una bevanda | Provenienza; per i vini ≠ denominazione (DOC/DOCG) | Bevanda | — |
| Produttore | Chi fabbrica la bevanda | ≠ Fornitore (chi rifornisce i movimenti); ≠ Azienda (il cliente) | Bevanda | — |
| Fornitore | Chi rifornisce i movimenti di acquisto (può essere anche cliente) | ≠ Produttore (chi fabbrica); ≠ Azienda | Movimento | — |
| Movimento | Traccia di uno spostamento, vendita o acquisizione di bottiglie e del relativo valore | = operazione; carico/scarico = tipi di movimento (vendita = scarico, fornitura/acquisizione = carico); prezzo di carico ≠ prezzo di vendita | Bevanda, Giacenza, Dipendente, Cantina, Fornitore | ~3/giorno (per cantina) |
| Giacenza | Quantità disponibile di una bevanda in una cantina, in bottiglie. Attributo del **Listino** (coppia bevanda-cantina), **derivato** dai movimenti (carichi − scarichi), memorizzato per efficienza e mantenuto coerente via trigger | = scorta / stock / disponibilità | Listino, Movimento | — |
| Fornitura | Movimento di acquisto dall'esterno (NON è un'entità: è un Movimento di tipo ACQUISTO con un Fornitore) | ≠ Produttore (chi fabbrica) e ≠ Fornitore (chi rifornisce) | Movimento, Fornitore | ~1-2/settimana (per cantina) |

> **Nota frequenze.** Le frequenze sono stimate **per singola cantina**, in uno scenario di riferimento di *esercizio commerciale di media dimensione*. La scala privato → catena è un **volume** (numero di cantine, già modellato da Azienda → N Cantine), che verrà ripreso in progettazione fisica.

---

## 3. Frasi omogenee per entità

### Azienda

- L'azienda è il cliente che utilizza il gestionale.
- Di ogni azienda interessano: id_azienda, ragione sociale, partita IVA, tipo, indirizzo della sede principale, email, PEC, telefono, titolare, sito web.
- Un'azienda possiede una o più cantine.

### Cantina

- Una cantina è il luogo fisico di stoccaggio delle bevande.
- Di ogni cantina interessano: id_cantina, nome, indirizzo, tipo.
- Ogni cantina è posseduta da una e una sola azienda.
- In una cantina lavorano uno o più dipendenti.
- Ogni cantina pubblica una o più carte vini e gestisce i propri listini.
- I movimenti di magazzino avvengono presso una cantina.

### Bevanda (e tipi: Vino / Birra / Analcolico / Superalcolico)

- Una bevanda è il generico prodotto stoccato e gestito.
- Di ogni bevanda interessano: id_bevanda, nome, categoria (discriminante), gradazione alcolica, volume, se biologica, data di inserimento, note.
- Ogni bevanda è prodotta da un produttore e può provenire da una regione.
- La giacenza non è un dato della bevanda ma del listino (vedi sotto): dipende dalla cantina.
- Una bevanda si specializza, in modo totale ed esclusivo (t,d), in vino, birra, superalcolico o analcolico.
- Un vino è caratterizzato da: annata, colore, tipologia, metodo, tipo blend, tipo denominazione, DOC, acidità; è composto da uno o più vitigni (con percentuale e annata), è ottenuto da una vinificazione e può essere sottoposto a un affinamento.
- Una birra è caratterizzata da: stile, tipo di fermentazione, IBU, EBC, densità originale e finale, se filtrata/pastorizzata/rifermentata, luppoli, malti, lievito.
- Un analcolico è caratterizzato da: categoria, ingredienti, se con zuccheri aggiunti, se frizzante.
- Un superalcolico è caratterizzato da: categoria, materia prima, tipo e numero di distillazioni, anni di invecchiamento, tipo botte, se torbato, ppm fenoli, blend.

### Vitigno / Vinificazione / Affinamento

- Un vitigno è la varietà d'uva da cui si ottiene un vino; di esso interessano nome (identificativo) ed eventuale sinonimo.
- Un vino è composto da uno o più vitigni; per ogni vitigno nel blend si registrano la percentuale e l'annata.
- La vinificazione è il processo di trasformazione dell'uva in vino (uno a uno con il vino); di essa interessano: id_vinificazione, mese di vendemmia, giorni di macerazione, tipo di fermentazione, tipo di vendemmia.
- L'affinamento è la fase di maturazione del vino successiva alla vinificazione; di esso interessano: id_affinamento, durata in legno (mesi), durata in bottiglia (mesi), tipo di legno, formato del legno.

### Regione

- Una regione rappresenta la provenienza geografica di una bevanda.
- Di ogni regione interessano: nome del paese (identificativo), codice ISO, nome della regione, zona.
- Una regione può essere provenienza di molte bevande.

### Produttore / Fornitore

- Un produttore è chi fabbrica una bevanda; di esso interessano: id_produttore, nome, paese, sito web.
- Un produttore produce una o più bevande.
- Un fornitore è chi rifornisce i movimenti di acquisto; di esso interessano: id_fornitore, ragione sociale, partita IVA, indirizzo, contatti, se è anche cliente.
- Un fornitore può essere coinvolto in più movimenti; è distinto dal produttore.

### Dipendente

- Un dipendente è l'operatore abilitato a usare/modificare il gestionale.
- Di ogni dipendente interessano: matricola (identificativo), nome, cognome, ruolo, username, email.
- Ogni dipendente lavora in una cantina.
- Un dipendente registra i movimenti e cura le carte vini.

### Movimenti

- Un movimento traccia un'operazione di magazzino (carico, scarico, vendita o acquisto) su una bevanda.
- Di ogni movimento interessano: id_movimento, tipo, quantità di bottiglie, prezzo unitario, data e ora.
- Ogni movimento riguarda una bevanda e avviene presso una cantina.
- Ogni movimento è registrato da un dipendente.
- I movimenti di acquisto coinvolgono un fornitore (chi rifornisce), distinto dal produttore (chi fabbrica la bevanda).
- La giacenza di una bevanda è aggiornata in base ai suoi movimenti.

### Carta vini / Listino

- Un listino registra, per una bevanda in una cantina, i dati commerciali e la giacenza; di esso interessano: id_listino, prezzo di vendita, prezzo di acquisto, IVA, giacenza (derivata dai movimenti), stato, data di ultimo aggiornamento.
- Una carta vini è una selezione di bevande in vendita, pubblicata da una cantina e curata da un dipendente.
- Di ogni carta vini interessano: id_carta_vini, titolo, stato, date di creazione/pubblicazione/archiviazione.
- Una carta vini contiene una o più voci, ciascuna riferita a una voce di listino, con un ordine e una descrizione di posizione.

---

## 4. Dizionario dei dati

> **Nota di modellazione.** Il dizionario adotta i nomi degli attributi già nella forma del livello logico (ponte verso il DDL). La generalizzazione di Bevanda è **totale ed esclusiva (t,d)**. La **giacenza** è un attributo del **Listino** (relativa alla coppia bevanda-cantina), **derivato** dai movimenti, memorizzato come colonna per efficienza (denormalizzazione motivata dalle letture frequenti, vedi Sez. 8) e mantenuto coerente dai trigger della Sez. 5.

### 4.1 Entità

| Entità | Descrizione | Attributi | Identificatore |
|---|---|---|---|
| Azienda | Cliente che possiede le cantine | id_azienda, ragione_sociale, p_iva, tipo, indirizzo_sede_principale, email, pec, telefono, titolare, sito_web, attivo | id_azienda |
| Cantina | Luogo fisico di stoccaggio delle bevande | id_cantina, nome, indirizzo, tipo | id_cantina (+ esterno: azienda) |
| Dipendente | Operatore abilitato a usare/modificare il gestionale | matricola, nome, cognome, ruolo, username, password_hash, email, attivo | matricola |
| Regione | Provenienza geografica di una bevanda | nome_paese, code_iso, nome_regione, zona | nome_paese |
| Vitigno | Varietà d'uva da cui si ottiene un vino | nome, sinonimo | nome |
| Produttore | Chi produce la bevanda | id_produttore, nome, paese, sito_web, attivo | id_produttore |
| Fornitore | Chi rifornisce i movimenti (può essere anche cliente) | id_fornitore, ragione_sociale, p_iva, is_cliente, is_fornitore, indirizzo, telefono, email, attivo | id_fornitore |
| Bevanda | Prodotto generico stoccato (entità padre della generalizzazione t,d) | id_bevanda, nome, categoria (discriminante), gradazione_alcolica, volume, is_biologico, data_inserimento, note, attivo | id_bevanda |
| Vino | Sottotipo di Bevanda | annata, colore, tipologia, metodo, tipo_blend, tipo_denominazione, doc, acidita | id_bevanda (ereditato) |
| Birra | Sottotipo di Bevanda | stile, tipo_fermentazione, ibu, ebc, densita_originale, densita_finale, is_filtrata, is_pastorizzata, is_rifermentata, luppoli, malti, lievito | id_bevanda (ereditato) |
| Super_alcolico | Sottotipo di Bevanda | categoria, materia_prima, tipo_distillazione, numero_distillazioni, anni_invecchiamento, tipo_botte, is_torbato, ppm_fenoli, blend | id_bevanda (ereditato) |
| Analcolico | Sottotipo di Bevanda | categoria, ingredienti, has_zuccheri_aggiunti, is_frizzante | id_bevanda (ereditato) |
| Vinificazione | Processo di trasformazione dell'uva in vino (1:1 con Vino) | id_vinificazione, mese_vendemmia, giorni_macerazione, tipo_fermentazione, tipo_vendemmia | id_vinificazione |
| Affinamento | Fase di maturazione del vino (0:1 con Vino) | id_affinamento, durata_legno_mesi, durata_bottiglia_mesi, tipo_legno, formato_legno | id_affinamento |
| Movimenti | Carico/scarico di magazzino di bevande | id_movimento, tipo (CARICO/SCARICO/VENDITA/ACQUISTO), quantita_bottiglie, prezzo_unitario, data_ora | id_movimento |
| Listino | Dati di vendita/acquisto e giacenza di una bevanda in una cantina | id_listino, prezzo_vendita, prezzo_acquisto, iva, giacenza (derivato dai movimenti, memorizzato), attivo, data_ultimo_aggiornamento | id_listino |
| Carta vini | Selezione di bevande in vendita, pubblicata da una cantina | id_carta_vini, titolo, stato, data_creazione, data_pubblicazione, data_archiviazione, attivo | id_carta_vini |

### 4.2 Relationship

| Relationship | Descrizione | Entità coinvolte | Attributi | Cardinalità (min,max) |
|---|---|---|---|---|
| Possiede | Un'azienda possiede una o più cantine | Azienda, Cantina | — | Azienda (1,N) – Cantina (1,1) |
| Lavora_in | Un dipendente lavora in una cantina | Dipendente, Cantina | — | Dipendente (1,1) – Cantina (0,N) |
| Produce | Un produttore produce le bevande | Produttore, Bevanda | — | Produttore (0,N) – Bevanda (1,1) |
| Proviene | Una bevanda proviene da una regione | Bevanda, Regione | — | Bevanda (0,1) – Regione (0,N) |
| Generalizzazione | Bevanda si specializza nei 4 tipi (totale ed esclusiva, t,d) | Bevanda → Vino/Birra/Super_alcolico/Analcolico | discriminante: categoria | copertura totale + esclusiva |
| Viene_vinificato | Un vino è ottenuto da una vinificazione | Vino, Vinificazione | — | Vino (1,1) – Vinificazione (1,1) |
| Viene_affinato | Un vino può essere sottoposto a un affinamento | Vino, Affinamento | — | Vino (0,1) – Affinamento (1,1) |
| Composto | Un vino è un blend di uno o più vitigni | Vino, Vitigno | percentuale, annata_vitigno | Vino (1,N) – Vitigno (0,N) |
| Registra | Un dipendente registra i movimenti | Dipendente, Movimenti | — | Dipendente (0,N) – Movimenti (1,1) |
| Avviene_in | Un movimento avviene presso una cantina | Movimenti, Cantina | — | Movimenti (1,1) – Cantina (0,N) |
| Coinvolge | Un movimento (acquisto) coinvolge un fornitore | Movimenti, Fornitore | — | Movimenti (0,1) – Fornitore (0,N) |
| Riguarda | Una voce di listino riguarda una bevanda | Listino, Bevanda | — | Listino (1,1) – Bevanda (0,N) |
| Contiene | Una cantina ha i propri listini | Cantina, Listino | — | Listino (1,1) – Cantina (0,N) |
| Pubblica | Una cantina pubblica le carte vini | Cantina, Carta vini | — | Carta vini (1,1) – Cantina (0,N) |
| Cura | Un dipendente cura una carta vini | Dipendente, Carta vini | — | Carta vini (1,1) – Dipendente (0,N) |
| Contiene_voce | Una carta vini contiene voci di listino | Carta vini, Listino | ordine, descrizione_posizione | Carta vini (0,N) – Listino (0,N) |

---

## 5. Vincoli non esprimibili graficamente

**Giacenza / movimenti** (→ trigger su `movimenti`)

- La giacenza di una bevanda non può diventare negativa (`giacenza >= 0`).
- Un movimento di scarico/vendita non può superare la giacenza attuale della bevanda.
- La giacenza di una bevanda deve restare coerente con la somma dei suoi movimenti (carichi − scarichi): va aggiornata automaticamente a ogni movimento.

**Prezzi** (→ trigger/check su `listino`)

- Il prezzo di vendita di una voce di listino dovrebbe essere ≥ del prezzo di acquisto (no vendita sottocosto).

**Coerenza della generalizzazione (t,d)** (→ trigger sui sottotipi)

- Ogni bevanda ha esattamente una specializzazione, coerente con `categoria` (un `id_bevanda` presente in `vino` ⇒ `categoria = 'VINO'`, ecc.).
- Solo le bevande di categoria VINO possono avere vinificazione, affinamento e vitigni associati.

**Vino / vitigni**

- Le percentuali dei vitigni che compongono un vino (`vino_vitigno.percentuale`) devono sommare a 100%.

**Movimenti / fornitore**

- Un movimento di tipo ACQUISTO deve riferirsi a un fornitore; gli altri tipi (vendita/scarico interno) no.

**Carta vini (date)**

- Per una carta vini: `data_pubblicazione >= data_creazione` e `data_archiviazione >= data_pubblicazione`.

**Carta vini (coerenza di cantina)**

- Tutte le voci di listino contenute in una carta vini devono appartenere alla **stessa cantina** che pubblica la carta. (La relazione `Pubblica` carta->cantina è mantenuta per efficienza ma è ridondante rispetto al cammino carta->listino->cantina, vedi Sez. 8.1: questo vincolo ne garantisce la coerenza.)

---

## 6. Schema ER (riferimento)

![Schema ER — MyProject](db_vect.svg)

---

# Parte II — Progettazione logica

> La progettazione logica procede in due fasi: **ristrutturazione** dello schema ER
> (sez. 7-9), guidata dal carico applicativo, e **traduzione** nel modello relazionale
> (sez. 10). La ristrutturazione parte dall'analisi di volumi e operazioni.

## 7. Tavola dei volumi e delle operazioni

> **Scenario di riferimento:** sistema multi-tenant a regime — un unico database condiviso
> da tutte le aziende clienti, con il catalogo *Bevanda* globale. La colonna *Volume* conta
> quindi le istanze **totali nel sistema**, ricavate dai parametri-base sotto.
> **Orizzonte temporale** per i dati che si accumulano (movimenti): ~2-3 anni di esercizio
> prima dell'archiviazione periodica.

**Parametri-base** (da cui si ricavano le righe per moltiplicazione): aziende ~10^2-10^3;
cantine per azienda ~1-5; dipendenti per cantina ~5-30; bevande nel catalogo globale
~10^5-10^6; bevande a magazzino per cantina ~10^2-10^3; movimenti/giorno per cantina ~50;
~300 giorni di esercizio/anno.

### 7.1 Tavola dei volumi

| Concetto | Tipo (E/R) | Volume (istanze stimate) | Note / come l'ho stimato |
|---|---|---|---|
| Azienda | E | 10^2-10^3 | prodotto rivolto ad aziende, crescita per passaparola; oltre questa scala servirebbe un rework dell'infrastruttura |
| Cantina | E | 10^2-10^4 | Aziende x cantine per azienda (1-5) |
| Dipendente | E | 10^3-10^5 | Cantine x addetti per cantina (5-30) |
| Bevanda (catalogo) | E | 10^5-10^6 | catalogo globale condiviso, sostanzialmente statico; inflazionato da annate/cuvée/produttori diversi |
| Vino (sottotipo) | E | 10^5-10^6 | quota dominante del catalogo (servizio specializzato sui vini) |
| Birra / Analcolico / Super_alcolico | E | 10^3-10^5 | nicchia rispetto ai vini |
| Movimenti | E | 10^7-10^8 | Cantine x ~50/gg x ~300gg x 2-3 anni. ⚠ tabella dominante; **cresce in modo illimitato** -> archiviazione periodica |
| Listino | E | 10^4-10^7 | Cantine x bevande a magazzino per cantina (10^2-10^3) |
| Carta vini | E | 10^3-10^5 | Cantine x carte per cantina (8-30); selezione consultabile dal cliente per ordinare |
| Produttore / Fornitore | E | 10^4-10^5 | i produttori/fornitori al mondo sono decine di migliaia |
| Composto (vino-vitigno) | R | ~2,5 x Vino (10^5-10^6) | (vitigni medi per vino ~2-3) x n. vini; scala con Vino |
| Contiene_voce (carta-listino) | R | 10^4-10^6 | Carte vini x voci per carta |

### 7.2 Tavola delle operazioni

| # | Operazione | Tipo (I/B) | Frequenza (per cantina) |
|---|---|---|---|
| O1 | Registra un movimento (carico/scarico/vendita) | I | ~50 / serata |
| O2 | Consulta la giacenza di una bevanda | I | ~50 / serata |
| O3 | Visualizza / stampa una carta vini | I | ~10-30 / serata |
| O4 | Inserisci una nuova bevanda a catalogo | I | ~1-5 / settimana |
| O5 | Report forniture / movimenti del mese | B | ~2 / mese |

---

## 8. Analisi delle ridondanze

**Ridondanza analizzata:** la **giacenza** (quantità disponibile in bottiglie) è
derivabile dai Movimenti (somma carichi − somma scarichi). Poiché *Bevanda* è il
catalogo globale, la giacenza è relativa alla coppia (bevanda, cantina): vive quindi
su **Listino**. Si valuta se **memorizzarla** come colonna su Listino (mantenuta da
trigger) oppure **ricalcolarla al volo** dai movimenti a ogni consultazione.

**Periodo di riferimento:** una serata di servizio, una singola cantina. Frequenze
(dalla tavola operazioni): O2 *consulta giacenza* ~50/serata; O1 *registra movimento*
~50/serata (un movimento per bottiglia, tracciabilità per-bottiglia). Convenzione:
una **scrittura** conta **doppio** (lettura del blocco + riscrittura).

`M` = numero di movimenti già accumulati in archivio per quella bevanda in quella
cantina (cresce nel tempo: i movimenti non si cancellano).

| Operazione | A) giacenza memorizzata (su Listino) | B) giacenza derivata dai movimenti |
|---|---|---|
| O2 — consulta giacenza (×50) | legge 1 riga Listino = 1 L → **50** | somma gli M movimenti = M L → **50·M** |
| O1 — registra movimento (×50) | scrivi mov (1 S) + leggi giacenza (1 L) + aggiorna giacenza (1 S) = 5 → **250** | scrivi mov (1 S) = 2 → **100** |
| **Totale accessi / serata** | **300** (stabile) | **50·M + 100** (cresce con M) |

**Punto di pareggio:** B conviene solo se `50·M + 100 < 300`, cioè `M < 4`. La derivazione
sarebbe più economica solo finché ogni bevanda ha meno di ~4 movimenti in archivio; ma
*Movimenti* è la tabella che cresce di più, quindi M supera 4 dopo pochi giorni di
esercizio e da lì il vantaggio di A aumenta nel tempo. In più, in un gestionale di
magazzino la giacenza si consulta in continuazione (ogni vendita la verifica): le
**letture dominano**, e la derivazione pagherebbe la scansione della tabella più grande
del database a ogni lettura.

**Decisione:** si **mantiene la giacenza memorizzata** come colonna su Listino,
aggiornata automaticamente dai trigger sui movimenti (Sez. 5). Si accetta la ridondanza
e il costo di mantenimento in cambio di letture a costo costante. *(Variante applicativa
possibile: bufferizzare gli aggiornamenti a fine servizio per ridurre le scritture, a
costo di una giacenza non aggiornata in tempo reale durante il servizio.)*

### 8.1 Altre ridondanze considerate

Oltre alla giacenza (attributo derivabile da altre entità), si valutano le altre due
forme di ridondanza.

**Relazioni derivabili da un ciclo.**

- **Avviene_in (Movimenti–Cantina).** La cantina di un movimento è ricavabile dal ciclo
  `Movimenti —Registra-> Dipendente —Lavora_in-> Cantina`, ammessa la regola "un dipendente
  registra movimenti solo nella propria cantina". La relazione è quindi formalmente
  ridondante. **Si decide di mantenerla**: i movimenti vengono interrogati per cantina di
  continuo (è la base del calcolo della giacenza) e la regola dipendente↔cantina non è
  stabile nel tempo (un dipendente può essere riassegnato). La ridondanza è accettata per
  efficienza e robustezza.
- **Pubblica (Carta vini–Cantina).** La cantina di una carta vini è ricavabile dal cammino
  `Carta vini —Contiene_voce-> Listino —Contiene-> Cantina`. **Si decide di mantenerla** per
  l'accesso diretto carta->cantina; ne consegue però un vincolo di coerenza (tutte le voci
  di una carta devono appartenere alla cantina che la pubblica) inserito tra i vincoli non
  grafici (Sez. 5).

**Attributi derivabili non memorizzati.** Il prezzo IVA-incluso di una voce di listino
(`prezzo_vendita` + `iva`) e il valore di una riga di movimento (`quantita_bottiglie x
prezzo_unitario`) sono calcolati al volo e non memorizzati.

**Aggregati non memorizzati.** Indicatori come il valore di magazzino o il fatturato per
cantina sono derivabili dai movimenti; essendo richiesti solo in report periodici (O5,
batch, frequenza bassa) si calcolano all'occorrenza e non si memorizzano.

---

## 9. Ristrutturazione dello schema ER

### 9.1 Eliminazione della generalizzazione (Bevanda → 4 tipi, t,d)

La generalizzazione `Bevanda → {Vino, Birra, Analcolico, Super_alcolico}` è totale ed
esclusiva (t,d). Tra le tre vie possibili (accorpamento nel genitore, accorpamento nei
figli, sostituzione con relationship) si sceglie la **sostituzione con relationship**:

- si **mantiene la tabella padre `Bevanda`** con id e attributi comuni;
- si creano **4 tabelle figlie** (Vino, Birra, Analcolico, Super_alcolico), ciascuna con i
  propri attributi specifici e **PK = FK verso Bevanda** (legame 1:1);
- il discriminante `categoria` su Bevanda indica la figlia corrispondente.

**Motivazione.** Bevanda è il catalogo globale ed è **fortemente referenziata** (Listino,
Movimenti, Produce, Proviene): mantenerla come entità unica dà alle loro FK un solo
bersaglio e permette le query sull'intero catalogo senza UNION. Inoltre i sottotipi hanno
**molti attributi distinti** (Vino ~8, Birra ~12, Super_alcolico ~9, Analcolico ~4):
tenerli in tabelle separate evita le ~33 colonne in gran parte NULL che produrrebbe
l'accorpamento nel genitore. Il costo (un join per ottenere bevanda + dettaglio del
sottotipo) è accettabile.

**Vincolo conseguente** (già in Sez. 5): essendo la generalizzazione t,d, ogni `id_bevanda`
deve comparire in **esattamente una** delle 4 tabelle figlie, coerentemente con `categoria`.

### 9.2 Eliminazione degli attributi multivalore

Alcuni attributi dei sottotipi sono di fatto **liste** (più valori per una stessa istanza)
e non sono ammessi nel modello logico. Si eliminano trasformandoli in una tabella di
collegamento con chiave composta. Trattandosi di un gestionale di magazzino/vendita (non di
produzione), di questi valori interessa il **solo nome**: non si modellano dosi o quantità,
che riguarderebbero la fabbricazione del prodotto.

| Attributo multivalore | Entità | Trasformazione (PK = tutta la coppia) |
|---|---|---|
| `luppoli` | Birra | `birra_luppolo(id_bevanda, nome_luppolo)` |
| `malti` | Birra | `birra_malto(id_bevanda, nome_malto)` |
| `ingredienti` | Analcolico | `analcolico_ingrediente(id_bevanda, nome_ingrediente)` |

Ogni `id_bevanda` è FK verso la rispettiva tabella figlia (Sez. 9.1).

**Casi non multivalore:**
- `vitigni` del Vino: già modellato come relationship **Composto** (N:M Vino–Vitigno con
  attributi `percentuale`, `annata_vitigno`) -> già normalizzato, è il modello di riferimento.
- `blend` del Super_alcolico: è un flag descrittivo (è un blend / nota), non una lista ->
  resta attributo atomico su Super_alcolico.

### 9.3 Scelta degli identificatori primari

Per le **entità** si adotta uno stile uniforme a **chiave surrogata**: ogni entità ha una
colonna `id_…` numerica come PK. La scelta privilegia semplicità e stabilità delle chiavi
(criteri: no opzionalità, semplicità, uso frequente nei join) ed è comoda per
l'implementazione (FK sempre a singola colonna, ORM-friendly).

**Avvertenza di normalizzazione.** Il surrogato non elimina le dipendenze funzionali tra
gli attributi naturali: la normalizzazione (Sez. 10 e forme normali) va comunque condotta
sulle **chiavi candidate naturali**, non sul surrogato, che altrimenti maschererebbe le
violazioni. Di conseguenza ogni chiave naturale resta protetta da un vincolo `UNIQUE`.

| Entità | PK | Vincolo / note |
|---|---|---|
| Regione | id_regione | `UNIQUE(nome_paese)` |
| Vitigno | id_vitigno | `UNIQUE(nome)` |
| Dipendente | id_dipendente | `UNIQUE(matricola)` |
| Cantina | id_cantina | FK `id_azienda`; opz. `UNIQUE(id_azienda, numero)` |
| (altre entità) | id_… | surrogato già presente nel dizionario (Sez. 4) |

**Tabelle di collegamento (N:M).** Per le relazioni molti-a-molti si usa la **PK composta**
dalle FK coinvolte (è già univoca e significativa, evita un surrogato inutile):

- `Composto(id_bevanda, id_vitigno)` + attributi `percentuale`, `annata_vitigno`
- `Contiene_voce(id_carta_vini, id_listino)` + attributi `ordine`, `descrizione_posizione`
- `birra_luppolo(id_bevanda, nome_luppolo)`, `birra_malto(id_bevanda, nome_malto)`,
  `analcolico_ingrediente(id_bevanda, nome_ingrediente)`

---

## 10. Schema logico relazionale

> **Notazione:** `R(`**PK in grassetto**`, attributi, FK -> Tabella)`. Gli attributi in
> grassetto formano la chiave primaria; `FK -> T` indica una foreign key verso `T`;
> `[N]` = nullable, `[U]` = vincolo UNIQUE. La traduzione applica le scelte delle Sez. 8-9.

**Anagrafiche e struttura aziendale**

- Azienda(**id_azienda**, ragione_sociale, p_iva, tipo, indirizzo_sede_principale, email, pec, telefono, titolare, sito_web, attivo)
- Cantina(**id_cantina**, nome, indirizzo, tipo, id_azienda -> Azienda)
- Dipendente(**id_dipendente**, matricola [U], nome, cognome, ruolo, username, password_hash, email, attivo, id_cantina -> Cantina)
- Regione(**id_regione**, nome_paese [U], code_iso, nome_regione, zona)
- Produttore(**id_produttore**, nome, paese, sito_web, attivo)
- Fornitore(**id_fornitore**, ragione_sociale, p_iva, is_cliente, is_fornitore, indirizzo, telefono, email, attivo)
- Vitigno(**id_vitigno**, nome [U], sinonimo)

**Bevanda e sottotipi** (generalizzazione tradotta con relationship 1:1, Sez. 9.1)

- Bevanda(**id_bevanda**, nome, categoria, gradazione_alcolica, volume, is_biologico, data_inserimento, note, attivo, id_produttore -> Produttore, id_regione -> Regione [N])
- Vino(**id_bevanda** -> Bevanda, annata, colore, tipologia, metodo, tipo_blend, tipo_denominazione, doc, acidita)
- Birra(**id_bevanda** -> Bevanda, stile, tipo_fermentazione, ibu, ebc, densita_originale, densita_finale, is_filtrata, is_pastorizzata, is_rifermentata, lievito)
- Super_alcolico(**id_bevanda** -> Bevanda, categoria, materia_prima, tipo_distillazione, numero_distillazioni, anni_invecchiamento, tipo_botte, is_torbato, ppm_fenoli, blend)
- Analcolico(**id_bevanda** -> Bevanda, categoria, has_zuccheri_aggiunti, is_frizzante)

**Dettagli del vino** (1:1 con Vino)

- Vinificazione(**id_vinificazione**, mese_vendemmia, giorni_macerazione, tipo_fermentazione, tipo_vendemmia, id_bevanda -> Vino [U])
- Affinamento(**id_affinamento**, durata_legno_mesi, durata_bottiglia_mesi, tipo_legno, formato_legno, id_bevanda -> Vino [U])

**Magazzino e vendita**

- Listino(**id_listino**, prezzo_vendita, prezzo_acquisto, iva, giacenza, attivo, data_ultimo_aggiornamento, id_cantina -> Cantina, id_bevanda -> Bevanda) — UNIQUE(id_cantina, id_bevanda)
- Movimenti(**id_movimento**, tipo, quantita_bottiglie, prezzo_unitario, data_ora, id_bevanda -> Bevanda, id_cantina -> Cantina, id_dipendente -> Dipendente, id_fornitore -> Fornitore [N])
- Carta_vini(**id_carta_vini**, titolo, stato, data_creazione, data_pubblicazione, data_archiviazione, attivo, id_cantina -> Cantina, id_dipendente -> Dipendente)

**Tabelle di collegamento** (N:M e attributi multivalore, PK composta)

- Composto(**id_bevanda** -> Vino, **id_vitigno** -> Vitigno, percentuale, annata_vitigno)
- Contiene_voce(**id_carta_vini** -> Carta_vini, **id_listino** -> Listino, ordine, descrizione_posizione)
- birra_luppolo(**id_bevanda** -> Birra, **nome_luppolo**)
- birra_malto(**id_bevanda** -> Birra, **nome_malto**)
- analcolico_ingrediente(**id_bevanda** -> Analcolico, **nome_ingrediente**)

> **Note di traduzione (scelte adottate).**
> 1. **Movimenti** referenzia direttamente `id_bevanda` e `id_cantina`: la `giacenza` su
>    Listino si deriva sommando i movimenti con stessa (bevanda, cantina). Il legame diretto
>    movimento->cantina è la relazione `Avviene_in` mantenuta per efficienza (Sez. 8.1).
>    *Alternativa:* far puntare Movimenti a `id_listino` (che già codifica bevanda+cantina).
> 2. **Vinificazione/Affinamento** sono tradotte come relazioni separate con FK 1:1 verso
>    Vino. *Alternativa:* fondere Vinificazione dentro Vino (1:1 obbligatorio su entrambi i
>    lati); si è preferito tenerle distinte per chiarezza concettuale.
> 3. La FK `id_regione` su Bevanda è nullable (provenienza opzionale); tutte le altre FK
>    delle entità sono NOT NULL salvo `id_fornitore` su Movimenti (solo per i movimenti di
>    acquisto).

---

## 11. Verifica delle forme normali

> Lo schema logico (Sez. 10) deriva metodicamente da un ER ben formato — ogni entità
> rappresenta un solo concetto e ogni associazione è reificata correttamente — quindi è
> **già sostanzialmente in 3NF per costruzione**. Questa sezione lo **verifica**
> formalmente (1NF -> 2NF -> 3NF) e documenta i punti in cui una forma normale è stata
> **rotta deliberatamente** per ragioni di carico.
>
> **Avvertenza metodologica (Sez. 9.3).** L'analisi è condotta sulle **chiavi candidate
> naturali** (quelle protette da `UNIQUE`), non sui surrogati `id_…`: essendo chiavi
> inventate da cui ogni attributo dipende banalmente, i surrogati **maschererebbero** le
> dipendenze funzionali reali fra gli attributi naturali e farebbero apparire 3NF qualsiasi
> tabella. **Esito anticipato:** lo schema è in 3NF, **salvo due denormalizzazioni
> deliberate** (giacenza e `Movimenti.id_cantina`), già motivate nell'analisi delle
> ridondanze (Sez. 8 e 8.1).

### 11.1 Prima forma normale (1NF)

Tutte le colonne sono **atomiche**: un solo valore per cella, nessun gruppo ripetuto. Gli
unici attributi originariamente multivalore — `luppoli` e `malti` della Birra,
`ingredienti` dell'Analcolico — sono già stati eliminati in fase di ristrutturazione
(Sez. 9.2), trasformandoli nelle tabelle `birra_luppolo`, `birra_malto` e
`analcolico_ingrediente`. Nessuna relazione contiene liste o gruppi ripetuti -> **tutto lo
schema è in 1NF**.

### 11.2 Seconda forma normale (2NF)

La 2NF riguarda **solo** le dipendenze **parziali** da una chiave **composta** (un attributo
non-chiave che dipende da una sola parte della PK).

- **17 entità a PK semplice** (surrogato `id_…`): una relazione in 1NF con PK semplice è
  **automaticamente in 2NF**, perché non esiste "una parte" della chiave da cui un attributo
  possa dipendere parzialmente.
- **5 tabelle a PK composta** (junction N:M e multivalore) — le uniche da verificare:
  - `Composto(`**id_bevanda, id_vitigno**`, percentuale, annata_vitigno)`: `percentuale` e
    `annata_vitigno` dipendono dalla **coppia intera** — l'annata è quella di *quel vitigno
    in quel vino specifico*, non del vitigno in sé (lo stesso vitigno entra in blend di
    annate diverse in vini diversi). Nessuna dipendenza parziale.
  - `Contiene_voce(`**id_carta_vini, id_listino**`, ordine, descrizione_posizione)`: `ordine`
    e `descrizione_posizione` descrivono la posizione di *quella voce in quella carta* ->
    dipendono dalla coppia.
  - `birra_luppolo`, `birra_malto`, `analcolico_ingrediente`: **all-key** (nessun attributo
    non-chiave) -> banalmente in 2NF (e 3NF): non esiste attributo che possa dipendere in
    modo parziale o transitivo da alcunché.

-> **tutto lo schema è in 2NF**.

### 11.3 Terza forma normale (3NF)

La 3NF vieta le **dipendenze transitive** fra attributi non-chiave (`A -> B -> C`) e le
**colonne calcolate**. Condotta l'analisi sulle chiavi naturali, lo schema è in **3NF per
costruzione**: ogni tabella descrive una sola entità o associazione e i suoi attributi
descrivono direttamente la chiave. Le poche dipendenze funzionali fra attributi naturali
hanno come **determinante una chiave candidata** e quindi non violano la 3NF — per esempio
in `Regione` la FD `nome_paese -> code_iso` (il codice ISO è determinato dal paese) ha per
determinante `nome_paese`, che è chiave candidata (`UNIQUE`).

Inoltre, gli attributi derivabili che **non vengono memorizzati** (prezzo IVA-incluso di una
voce di listino, valore di una riga di movimento `quantita x prezzo`, aggregati di
report — Sez. 8.1) **preservano** la 3NF proprio perché calcolati al volo e non
materializzati: la violazione non è "esiste un valore calcolabile", è *salvarlo*.

Fanno eccezione **due attributi memorizzati che violano consapevolmente la 3NF**, già decisi
nell'analisi delle ridondanze:

1. **`giacenza` (su Listino) — colonna calcolata.** È derivabile dai `Movimenti`
   (Σ carichi - Σ scarichi per la coppia bevanda-cantina): memorizzarla la rende un dato
   **ridondante**, in violazione della regola "niente colonne calcolate". *Scelta
   deliberata* (Sez. 8): la giacenza si **legge** in continuazione (ogni vendita la verifica)
   mentre derivarla costerebbe la scansione della tabella più grande del database a ogni
   lettura; si accetta la ridondanza in cambio di letture a costo costante, mantenendo il
   valore coerente con i **trigger** sui movimenti (Sez. 5).

2. **`id_cantina` (su Movimenti) — dipendenza transitiva.** Vale la catena
   `id_movimento -> id_dipendente -> id_cantina`: un movimento è registrato da un dipendente
   (`Registra`), che lavora in una cantina (`Lavora_in`). Quindi un attributo non-chiave
   (`id_dipendente`) ne determina un altro non-chiave (`id_cantina`) -> dipendenza
   transitiva. *Scelta deliberata* (Sez. 8.1): i movimenti si interrogano **per cantina** di
   continuo (è la base del calcolo della giacenza) e la regola dipendente<->cantina **non è
   stabile** nel tempo — un dipendente può essere riassegnato, ma i suoi movimenti restano
   nella cantina in cui sono avvenuti -> tenere `id_cantina` diretta è più **robusto**, oltre
   che più efficiente.

Entrambe rispettano i **quattro criteri** di una buona denormalizzazione: fatta
deliberatamente, con un'ottima ragione, consapevoli del costo di consistenza (gestito via
trigger), e **documentata**. Le slide del corso si fermano alla 3NF: la BCNF non è
considerata.

### 11.4 Riepilogo

| Forma normale | Esito | Dettaglio |
|---|---|---|
| **1NF** | rispettata da tutto lo schema | colonne atomiche; multivalore già eliminati in Sez. 9.2 (luppoli/malti/ingredienti -> tabelle dedicate) |
| **2NF** | rispettata da tutto lo schema | 17 entità a PK semplice -> automatico; 5 a PK composta verificate (dipendenza piena su `Composto`/`Contiene_voce`; 3 all-key banali) |
| **3NF** | rispettata salvo 2 scelte deliberate | violazioni consapevoli: `giacenza` (colonna calcolata) e `Movimenti.id_cantina` (transitiva via dipendente), motivate in Sez. 8/8.1 e mantenute dai trigger |

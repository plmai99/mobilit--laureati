# Analisi della distribuzione spaziale e dei flussi di mobilità dei laureati nelle province italiane

Studio delle dinamiche di mobilità interna dei laureati in Italia su scala provinciale (anno 2021), con l'obiettivo di mappare la geografia del capitale umano e comprendere come le interdipendenze territoriali e i fattori socio-economici locali influenzino la capacità dei territori di attrarre o trattenere competenze elevate.

**Domanda di ricerca**: in che misura le interazioni spaziali e le caratteristiche socio-economiche provinciali spiegano i flussi migratori di capitale umano qualificato in Italia?


## Dati

- **Fonte**: [ISTAT BES](https://www.istat.it/it/benessere-e-sostenibilit%C3%A0) (Benessere Equo e Sostenibile)
- 107 province italiane (NUTS-3), anno 2021
- **Variabile dipendente**: `mobilità_laureati` — saldo migratorio dei laureati
- **Variabili esplicative** (13 candidate): quota di occupati nel settore culturale (`addetti_culturali`), competenze INVALSI (italiano e matematica), accesso a internet ultraveloce, tasso di NEET, quota di laureati residenti, trasporto pubblico locale, reddito pro capite, retribuzione media, tassi di occupazione (generale e femminile), brevetti EPO per milione di abitanti, quota di occupati ICT

## Metodologia

**1. Analisi esplorativa e descrittiva**

La variabile dipendente presenta media e mediana negative (rispettivamente -9,79 e -9,20): la condizione "normale" per una provincia italiana è un saldo migratorio negativo. Il coefficiente di variazione (1,65) conferma una fortissima eterogeneità territoriale. Distribuzione approssimativamente normale ma con picco spostato a sinistra dello zero.

Le variabili esplicative più asimmetriche (`tpl`, `brevetti`, `reddito_pro_capite`) sono state trasformate in logaritmo (`log` o `log1p` per gestire gli zeri), riducendo sensibilmente skewness e kurtosi.

**2. Analisi esplorativa spaziale**

Costruzione della matrice di pesi spaziali a contiguità **Queen**, standardizzata per riga:
- 107 province, connettività media di 4,45 vicini per unità
- Province isolate (1 solo link): Cagliari, Trieste; provincia più connessa: Firenze (9 link)
- Verifica della prima legge della geografia di Tobler

**Test di autocorrelazione spaziale globale**:
- **Moran's I = 0,585** (p < 2,2e-16): forte autocorrelazione spaziale positiva
- **Geary's C = 0,428** (p < 2,2e-16): conferma incrociata — i due indici concordi rendono la dipendenza spaziale un fenomeno pervasivo e non un artefatto statistico

**Mappa LISA (cluster locali)**:
- Cluster High-High (Nord): Lombardia, Emilia-Romagna, Veneto — province ad alta attrattività circondate da vicini altrettanto forti
- Cluster Low-Low (Sud): Campania, Calabria, Puglia, Sicilia — nucleo strutturale del brain drain

**3. Regressione OLS e selezione del modello**

- Modello completo (13 variabili) → selezione **backward stepwise** basata su AIC (da 432,32 a 424,48)
- Diagnosi di multicollinearità tramite **VIF**: `occupazione_fem` (VIF = 7,69, forte sovrapposizione con il reddito) rimossa dal modello finale (`mod2`), che ottiene VIF tutti sotto 5
- **R² aggiustato del modello OLS finale: 0,814**

**Batteria di test diagnostici su `mod2`**:

| Test | Scopo | p-value | Esito |
|---|---|---|---|
| Shapiro-Wilk (+ JB, KS) | Normalità residui | 0,7871 | ✅ Residui normali |
| Breusch-Pagan | Omoschedasticità | 0,6387 | ✅ Varianza costante |
| Durbin-Watson | Autocorrelazione residui | 0,04064 | ❌ Residui correlati |

Il modello OLS è statisticamente solido su tutti i fronti classici, ma il test di Durbin-Watson segnala la necessità di un modello spaziale.

**4. Selezione del modello spaziale (approccio specific-to-general)**

- **Moran test sui residui OLS**: p = 0,002653, Moran's I = 0,1756 → dipendenza spaziale residua confermata
- **Lagrange Multiplier test**: sia LM Error (p = 0,01064) che LM Lag (p = 0,00324) risultano significativi
- **Robust LM test**: Robust LM Error non significativo (p = 0,3558), Robust LM Lag significativo al 10% (p = 0,08353) → il modello **SAR** risulta più appropriato del SEM
- **Confronto SAR vs SDM**: il Likelihood Ratio test (p = 0,4129) mostra che l'aggiunta dei lag spaziali delle variabili esplicative (tipica dello SDM) non migliora significativamente il modello → si preferisce il SAR per parsimonia

## Risultati del modello finale (SAR)

$$Y = \rho WY + X\beta + \varepsilon$$

- **Pseudo-R² di Nagelkerke: 0,833** — AIC: 725,73
- **Rho = 0,216** (p = 0,005): circa il 21,6% della mobilità di una provincia è spiegato dalla mobilità delle province vicine

**Effetti diretti, indiretti e totali** (impact analysis):

| Variabile | Effetto diretto | Effetto indiretto | Effetto totale |
|---|---|---|---|
| log_reddito | 48,13 (p < 0,001) | 12,56 (p = 0,012) | 60,68 |
| log_tpl | 2,38 (p = 0,011) | 0,62 (p = 0,135) | 3,00 (p = 0,020) |
| laureati | 0,38 (p = 0,017) | 0,10 (p = 0,097) | 0,47 (p = 0,020) |
| log_brevetti | 1,88 (p = 0,080, 10%) | 0,49 (p = 0,151) | 2,37 (p = 0,081, 10%) |
| internet_ultraveloce | 0,09 (p = 0,074, 10%) | 0,02 (p = 0,191) | 0,12 (p = 0,085, 10%) |
| competenza_numerica | 0,21 (n.s.) | 0,06 (n.s.) | 0,27 (n.s.) |

Il **reddito pro capite** è il driver dominante e genera importanti spillover positivi sulle province limitrofe. Interessante il "risveglio" delle urban amenities (trasporto pubblico, internet ultraveloce) rispetto al modello OLS: nel modello spaziale, una volta ripulito l'effetto della dipendenza territoriale, questi fattori emergono come driver significativi, segno che nell'OLS classico il loro impatto era mascherato dalla distorsione spaziale.

## Conclusioni

Lo studio suggerisce che le politiche locali di attrazione del capitale umano non possono essere pensate in isolamento a livello di singola provincia. Per contrastare il fenomeno della fuga di cervelli non basta creare posti di lavoro generici: serve stimolare interi ecosistemi regionali, agendo simultaneamente su leve economiche (reddito) e infrastrutturali (trasporti e digitale). La mobilità dei laureati in Italia è un fenomeno di rete territoriale, non una competizione tra province isolate: senza interventi coordinati su scala macroregionale, il "moltiplicatore spaziale" continuerà a penalizzare le aree già in ritardo.

## Strumenti

R — `sf`, `spdep`, `spatialreg` (analisi spaziale, matrici di pesi, test di Moran e Geary, modelli SAR/SEM/SDM), `car` (VIF), `lmtest`, `nortest` (diagnostica OLS), `moments` (indici di forma), `ggcorrplot`, `mapview`, `leaflet` (mappe interattive), `stargazer`

## Struttura del repository

```
├── analisi_mobilita_laureati.R   # script completo dell'analisi
├── README.md
```

## Note

Il progetto richiede, oltre al dataset ISTAT BES in formato Excel, uno shapefile con la geometria delle province italiane (NUTS-3) per la componente di analisi spaziale.

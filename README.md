# I determinanti della mobilità dei laureati nelle province italiane: un'analisi econometrica spaziale (NUTS 3)

Analisi dei fattori socio-economici che influenzano la mobilità dei laureati a livello provinciale in Italia, con l'obiettivo di verificare se l'attrattività di un territorio dipenda non solo dai fondamentali economici classici (lavoro e reddito), ma anche da fattori "soft" come vivacità culturale e innovazione tecnologica. Data la natura territoriale dei dati, l'analisi individua e corregge gli effetti di dipendenza spaziale.

Progetto realizzato per il corso di **Analisi dei Dati Spaziali (ADS)**, Università degli Studi di Napoli Parthenope.

## Dati

- **Fonte**: BES ISTAT (Benessere Equo e Sostenibile)
- Campione di **107 province italiane (NUTS 3)**
- **Variabile dipendente**: mobilità dei laureati italiani (saldo/tasso di mobilità)
- **Variabili esplicative principali**:
  - `addetti_imprese_culturali` — densità di lavoratori nel settore creativo/culturale
  - `emigrazione_ospedaliera` — indice di efficienza dei servizi sanitari (proxy di qualità della vita)
  - `brevetti` — numero di brevetti depositati (proxy di innovazione)
  - `red_medio_pro_capite` — benessere economico diffuso
  - `tasso_occupazione` — dinamismo del mercato del lavoro locale

## Metodologia

**1. Diagnostica del modello OLS**

Stimato un modello di regressione lineare di base, sottoposto a una batteria di test diagnostici:

| Test | Scopo | p-value | Esito |
|---|---|---|---|
| Ramsey RESET | Forma funzionale | 0.1095 | ✅ Modello lineare corretto |
| Shapiro-Wilk | Normalità residui | 0.3200 | ✅ Residui normali |
| Breusch-Pagan | Omoschedasticità | 0.3509 | ✅ Varianza costante |
| Durbin-Watson | Autocorrelazione | 0.0214 | ❌ Autocorrelazione presente |
| VIF | Multicollinearità | < 6.0 | ✅ Coefficienti stabili |

Il modello OLS supera tutti i test classici tranne quello sull'incorrelazione dei residui — primo segnale della necessità di un modello spaziale.

**2. Diagnostica spaziale e selezione del modello**

I test di **Rao's Score (Lagrange Multiplier)** indicano che la dipendenza spaziale risiede nella struttura dell'errore, non nella variabile dipendente:
- RSerr: p < 0.001 (significativo)
- adjRSerr: p = 0.023 (significativo)
- adjRSlag: p = 0.215 (non significativo)

Questo motiva la scelta di un **Spatial Error Model (SEM)** anziché un modello Spatial Lag.

**Criterio di selezione (SEM vs SAC)**: è stato inizialmente considerato il modello più generale SAC (Spatial Autoregressive Combined). Il test del Rapporto di Verosimiglianza (LR test) tra SEM e SAC ha restituito un p-value di 0.2216 (non significativo): si accetta l'ipotesi di equivalenza statistica tra i due modelli e, per il principio di parsimonia, si seleziona il SEM, che corregge l'autocorrelazione dell'errore senza introdurre il parametro spaziale aggiuntivo ρ.

**3. Stima del modello SEM finale**

Matrice di pesi spaziali a contiguità **Queen**, standardizzata per riga (`style = "W"`).

- **Pseudo-R² di Nagelkerke**: 0.874 (l'87,4% della varianza spiegata)
- **AIC**: 756.89 (migliore rispetto a 764.67 dell'OLS)
- **Lambda (λ = 0.088)**: parametro spaziale significativo, a conferma dell'esistenza di cluster territoriali

**4. Analisi di robustezza**

Il modello è stato ristimato con una matrice di pesi a banda di distanza, in alternativa alla contiguità:
- Indice di Moran = 0.666 (fortissima autocorrelazione spaziale positiva)
- I coefficienti delle variabili principali (cultura, brevetti, occupazione) restano stabili e significativi
- La matrice di contiguità risulta comunque preferibile per efficienza statistica (AIC inferiore)

## Risultati

Il modello SEM identifica tre dimensioni distinte che spiegano la mobilità dei laureati:

**Opportunità economiche**
- Tasso di occupazione (β ≈ 0.546, driver principale): un aumento dell'1% nel tasso di occupazione provinciale si associa a un incremento di circa 0.55 punti nel tasso di mobilità
- Reddito medio pro capite (β ≈ 0.002, p < 0.001): un aumento di 1.000€ nel reddito medio provinciale genera un incremento di 2 unità nella mobilità

**Attrattività "soft" (classe creativa e innovazione)**
- Addetti alle imprese culturali (β ≈ 11.11): la variabile con l'impatto unitario più forte del modello — la vivacità culturale agisce come fattore di differenziazione territoriale, in linea con la teoria della "classe creativa" di Richard Florida
- Brevetti (β ≈ 0.055): l'innovazione tecnologica favorisce l'attrazione di capitale umano qualificato

**Qualità dei servizi (push factor)**
- Emigrazione ospedaliera (β ≈ -0.362): unico coefficiente negativo e significativo — funge da proxy dell'inefficienza dei servizi sanitari locali; una sanità carente agisce da fattore di repulsione per i laureati

Il parametro spaziale λ significativo conferma che questi fattori non agiscono in isolamento: il successo di una provincia nell'attrarre capitale umano si "contagia" alle province limitrofe, creando macro-aree di attrazione del talento che superano i confini amministrativi.

## Implicazioni

L'evidenza spaziale suggerisce che le politiche di attrazione del capitale umano non dovrebbero essere pensate a livello di singola provincia, ma su scala territoriale vasta, data l'interconnessione geografica rilevata dal modello. Investire solo su lavoro e reddito non basta: cultura, innovazione e qualità dei servizi pubblici sono leve complementari e statisticamente rilevanti.

## Strumenti

R — `sf`, `spdep`, `spatialreg` (analisi spaziale), `car` (VIF), `lmtest`, `nortest` (diagnostica), `moments` (indici di forma), `ggcorrplot`, `mapview`, `leaflet` (visualizzazione), `stargazer`

## Struttura del repository

```
├── analisi_mobilita_laureati.R   # script completo dell'analisi
├── README.md
```

## Note

Il progetto richiede, oltre al dataset BES ISTAT in formato Excel, uno shapefile con la geometria delle province italiane (NUTS-3) per la componente di analisi spaziale.

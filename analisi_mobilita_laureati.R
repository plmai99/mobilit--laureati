# tasso mobilità laureati 2021

library(readxl)
library(moments)
library(lmtest)
library(nortest)
library(car)
library(rcompanion)
library(sf)
library(tripack)
library(spdep)
library(spatialreg)
library(leaflet)
library(RColorBrewer)
library(spData)
library(ggplot2)
library(stargazer)
library(mapview)
library(MASS)
library(ggrepel)
library(tidyverse)
library(ggcorrplot)
library(gridExtra)
library(labstatR)
library(desk)
library(performance)
library(car)
#Rimosso percorso locale per rendere lo script portabile
#impostare percorso con setwd()
data <- read_excel("tml.xlsx")
View(data)
path=file.choose()
shp=st_read(path)
dataset=merge(shp,data, by='NUTS_ID')
View(dataset)
attach(dataset)



mapview(dataset) #crea mappa interattiva oggetto spaziale dataset direttamente in R visualizzabile nello spazio geografico
mapview(dataset, zcol= "mobilità_laureati") #crea mappa interattiva tematica (mappa coropletica) - zcol permette di scegliere la variabile da rappresentare
palette <- brewer.pal(5, "OrRd") #palette composta da 5 colori della scala "OrRd" (Arancione-Rosso).
mapview(dataset, zcol="mobilità_laureati", layer.name='Livelli di mobilità_laureati',at=quantile(mobilità_laureati), col.regions = palette)





###########eda
str(dataset)


# mobilità_laureati
#indici
summary(mobilità_laureati)

#Indici di variabilità
var(mobilità_laureati)
sd(mobilità_laureati)
cv(mobilità_laureati)


#Indici di forma
library(moments)
skewness(mobilità_laureati) 
kurtosis(mobilità_laureati) 


# Histogram e Densità
ggplot(dataset, aes(x = mobilità_laureati)) +
  geom_histogram(aes(y = ..density..), bins = 20, fill = "skyblue", color = "white") +
  geom_density(col = "red", lwd = 1) +
  labs(title = "Distribuzione della Mobilità dei Laureati", x = "Tasso di Mobilità", y = "Densità") +
  theme_minimal()


# calcola la matrice di correlazione
x=data[,c(3:16)] 
corr <- round(cor(x),2)
p.mat <- cor_pmat(x)
ggcorrplot(
  corr,
  p.mat = p.mat,
  hc.order = TRUE,
  type = "lower",
  lab = TRUE,
  insig = "blank"
)



# analisi delle variabili esplicative
summary(x)
# tpl
skewness(tpl)
skewness(log(tpl))
kurtosis(tpl) 
kurtosis(log(tpl))
#La variabile TPL presentava inizialmente una distribuzione fortemente non normale,
#caratterizzata da un'asimmetria positiva estrema ($Sk = 3.40$) e un'elevatissima curtosi ($K = 20.10$),
# segnali di una forte eterogeneità territoriale guidata dalle grandi aree metropolitane. 
#L'adozione della scala logaritmica ha permesso di normalizzare i dati, 
#riducendo l'asimmetria a $-0.36$ e la curtosi a $3.46$.
#Tale trasformazione garantisce la validità dell'inferenza statistica
# e permette di catturare correttamente l'elasticità 
#della mobilità dei laureati rispetto all'efficienza dei trasporti."

#brevetti
dataset$log_brevetti <- log1p(dataset$brevetti)
skewness(brevetti)
skewness(log1p(brevetti))
kurtosis(brevetti) 
kurtosis(log1p(brevetti))
#Anche per la variabile Brevetti, la trasformazione logaritmica (log1p) 
# si è rivelata fondamentale. Sebbene l'asimmetria originale ($Sk = 1.24$) 
# non fosse estrema come nel caso del TPL, la curtosi della variabile trasformata 
#($K = 3.06$) ha raggiunto un valore quasi coincidente con quello della distribuzione normale.
#Questo garantisce che i residui del modello non siano influenzati
# da outlier nelle province ad alta densità tecnologica,
#rendendo il coefficiente di regressione ($2.50$) 
#estremamente affidabile per spiegare l'attrattività dei laureati


# reddito pro capite
skewness(reddito_pro_capite)
skewness(log(reddito_pro_capite))
kurtosis(reddito_pro_capite) 
kurtosis(log(reddito_pro_capite))
#L'analisi degli indici di forma conferma la bontà della trasformazione: 
#la skewness del reddito si riduce da $0.30$ a $-0.10$, raggiungendo una
#quasi perfetta simmetria. La riduzione della curtosi a $2.23$ riflette
#la natura bimodale della distribuzione, evidenziando il divario economico 
#territoriale senza che questo pregiudichi la robustezza delle stime OLS e spaziali


# Istogramma del Reddito Originale
p1 <- ggplot(dataset, aes(x = reddito_pro_capite)) +
  geom_histogram(aes(y = ..density..), bins = 20, fill = "#D55E00", color = "white", alpha = 0.7) +
  geom_density(color = "black", lwd = 1) +
  labs(title = "Reddito Pro Capite (Originale)",
       subtitle = "Distribuzione asimmetrica",
       x = "Euro (€)", y = "Densità") +
  theme_minimal()

# Istogramma del Reddito Logaritmico 
p2 <- ggplot(dataset, aes(x = log(reddito_pro_capite))) + 
  geom_histogram(aes(y = ..density..), bins = 20, fill = "#0072B2", color = "white", alpha = 0.7) +
  geom_density(color = "black", lwd = 1) +
  labs(title = "Log-Reddito Pro Capite",
       subtitle = "Distribuzione normalizzata",
       x = "Log(Euro)", y = "Densità") +
  theme_minimal()

# Visualizzazione affiancata
grid.arrange(p1, p2, ncol = 2)
#Il confronto tra le distribuzioni evidenzia come la trasformazione logaritmica abbia corretto
#la forte asimmetria positiva del reddito originale, stabilizzando la varianza. La distribuzione 
#log-normale risultante permette di interpretare il coefficiente della regressione (pari a 42.38)
#in termini di elasticità, riducendo al contempo l'influenza distorsiva dei valori 
#estremi presenti nelle province a reddito più elevato.





####matice standardizzata####
list.queen<-poly2nb(dataset, queen=TRUE) 
list.queen 
summary(list.queen)
coords<-st_centroid(st_geometry(dataset),of_largest_polygon = TRUE) #la funzione definisce il centroide di ciascun poligono - of_largest polygon permette di usare nel caso di geometrie con più parti (es. isole) il centroide della parte più estesa
plot(st_geometry(dataset),col='lightgrey')
plot(list.queen,coords=coords,add=T,col='blue',lwd=2)
#listw
listw<-nb2listw(list.queen, style="W", zero.policy=TRUE) #lista di pesi spaziali che deriva dall'oggetto nb - zero.policy=T evita errori in presenza di unità senza vicini (assegna pesi nulli)
summary(listw)
#mat
W<-nb2mat(list.queen, style="W", zero.policy=TRUE)
View(W)




#######moran test
moran(dataset$mobilità_laureati,listw=listw, length(dataset$mobilità_laureati),Szero(listw), zero.policy=T) #restituisce I (Moran) e K (curtosi variabile)
moran.test(dataset$mobilità_laureati, listw, zero.policy=T)
#moran plot contiguità
moran.plot(dataset$mobilità_laureati,listw,zero.policy=T, 
           pch=20, 
           col="blue",
           main = "Moran Scatterplot")


#Geary C
geary.test(mobilità_laureati,listw,zero.policy = T)





#####Trasformazione logaritmica delle variabili chiave####
# Usiamo log1p(x) che è equivalente a log(x + 1) per gestire gli zeri

dataset$log_tpl <- log(dataset$tpl)
dataset$log_brevetti <- log1p(dataset$brevetti)
dataset$log_reddito <- log(dataset$reddito_pro_capite)
dataset$log_retribuzione <- log1p(dataset$retribuzione_media_dipendente)
dataset$log_ict <- log1p(dataset$pct_emp_ict) # Anche questa è molto piccola e asimmetrica
attach(dataset)



#####Procedura di selezione modello ols####
attach(dataset)
# Modello nullo (solo intercetta)
mod_null <- lm(mobilità_laureati ~ 1)
summary(mod_null)
# mod full
mod_full <- lm( mobilità_laureati ~ occupazione+neet+log_brevetti+addetti_culturali+competenza_alf+competenza_numerica+internet_ultraveloce+
                  laureati+log_tpl+log_retribuzione+log_reddito+
                  occupazione_fem+log_ict, data=dataset) 
summary(mod_full)

# Procedura backward - modello completo con tutte le variabili candidate
backward_mod <- step(mod_full,
                     scope = formula(mod_null),
                     direction = "backward")
summary(backward_mod)
AIC(backward_mod)


# mod1 = backward
mod1 <- lm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
             internet_ultraveloce + laureati + log_tpl + log_reddito + 
             occupazione_fem, data = dataset)
summary(mod1)
vif(mod1)
# vif: occupazione_fem >7, la escludiamo dal nostro modello

#mod2 <- occupazione_fem eliminata
mod2 <- lm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
             internet_ultraveloce + laureati + log_tpl + log_reddito, data = dataset)
summary(mod2)
#multicollinearità
vif(mod2)
#multicollinearità risolta



# linearità
plot(mod2,1) #grafico dei valori teorici vs. residui

reset.test(mod2)
# h0: lineare; h1  non lineare 
# non si rigetta h0 
# non si rigetta h0, modello correttamente specificato



#Calcolo dei residui (e)
residui=residuals(mod2) #calcola i residui del modello
residui

#Normalità dei residui
# Calcolo dei residui standardizzati
residui_std <- rstandard(mod2) #calcola i residui standardizzati
dataset$residui_std=residui_std #permette di aggiungere nella matrice dei dati il vettore dei residui
View(dataset)

#Verifica sui residui standardizzati
qqnorm(residui_std, main="Q-Q Plot dei residui standardizzati")
qqline(residui_std, col="red") # Aggiunge una linea di riferimento
hist(residui_std,col="lightblue",main="Istogramma dei residui")
plotNormalHistogram(residui_std)

# Verifica dell'ipotesi di normalità dei residui
shapiro.test(residui) #test di Shapiro-Wilk per la normalità dei residui
shapiro.test(residui_std) #test di Shapiro-Wilk per la normalità dei residui
# h0: I residui seguono una distribuzione Normale
# h1: residui non normali
# p>a non si rigetta h0: residui normali

ks.test(residui, "pnorm", mean=mean(residui), sd=sd(residui)) #pnorm indica il confronto con la distribuzione Normale
ks.test(residui_std, "pnorm") #media è zero e standard deviation unitaria
library(tseries)
jarque.bera.test(residui)
jarque.bera.test(residui_std)


#library(desk)
jb.test(residui)
jb.test(residui_std)

plot(mod2,2)



# Verifica dell'ipotesi di omoschedasticità
bptest(mod2) #Breusch-Pagan test
# h0: Omoschedasticità (varianza dell'errore è costante)
# h1: eteroschedasticità (varianza cambia al variare delle X)
# p>a non si rigetta h0, residui omoschedastici


plot(mod2,1) #1 residui
plot(mod2,3) #3 radice residui standardizzati


#outliers
plot(mod2,5)

check_outliers(mod2) #rilevare outliers nei residui
influence.measures(mod2) #include anche la Cook distance 
# non ci sono outliers


# Verifica dell'ipotesi di incorrelazione dei residui
dwtest(mod2) #Durbin-Watson test
# h0 :residui incorrelati
# h1: residui correlati
# p<a, si rigetta h0: residui correlati

# il test di DW cattura la dipendenza spaziale
# questo risultato è la conferma definitiva che sono necessari i modelli spaziali



# moran test 
moran.lm<-lm.morantest(mod2, listw, alternative="two.sided") #verifica la presenza di autocorrelazione spaziale nei residui del modello lineare stimato
moran.lm
LM_tests<-lm.RStests(mod2,listw,test="all",zero.policy = T) 
LM_tests


# SEM
sem<-errorsarlm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
                  internet_ultraveloce + laureati + log_tpl + log_reddito, 
                data = dataset, listw) 
summary(sem,Nagelkerke=TRUE)
AIC(sem)


# SAR
sar <- lagsarlm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
                  internet_ultraveloce + laureati + log_tpl + log_reddito,
                data = dataset,         # <-- Devi specificare il nome del dataset
                listw = listw,    # <-- Devi specificare l'oggetto dei pesi
                tol.solve = 6.2817e-17)
summary(sar, Nagelkerke=TRUE)
# rho > 0, dipendenza spaziale positiva
#il tasso di mobilità dei laureati di una provincia è influenzato anche dal tasso dei laureati delle province vicine



# confrontamo il sar con le sue estensioni (sac e sdm)
#SAC
sac<-sacsarlm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
                internet_ultraveloce + laureati + log_tpl + log_reddito,
              data = dataset, listw, method="LU")
summary(sac,Nagelkerke=TRUE)


LR.Sarlm(sac, sar)# h0 Il modello corretto è il SAR (lambda = 0)
#p>a accetto h0

#SDM
sdm<-lagsarlm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
                internet_ultraveloce + laureati + log_tpl + log_reddito,
              data = dataset, listw, type = "mixed", tol.solve = 1.10e-20)
summary(sdm,Nagelkerke=TRUE)

LR.Sarlm(sdm,sar)#h0: Il modello corretto è il sar (theta=0)
# p>a si accetta h0
# il modello sar non deve essere esteso a sdm



# effetti diretti e effetti indiretti (spillover) Sar, sac, sdm
W2 <- as(listw, 'CsparseMatrix')
trMat <- trW(W2, type="mult")

impact_sar <- impacts(sar,tr=trMat,R=100)
impact_sar
summary(impact_sar, zstats=TRUE, shirt=TRUE)


########




# matrice a banda di distanza
#distance
coords<-st_centroid(st_geometry(dataset),of_largest_polygon = TRUE)
W_dist <- dnearneigh(coords,0,100000)   # - 100 km - 
W_dist
# trasforma la lista di vicini per distanza in un oggetto listw
W_dist_listw <- nb2listw(W_dist, style="W", zero.policy=TRUE)

# Esegui nuovamente gli LM Tests usando l'oggetto corretto
LM_tests <- lm.RStests(mod2, W_dist_listw, test="all", zero.policy=TRUE)
LM_tests




# SEM2
sem2<-errorsarlm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
                   internet_ultraveloce + laureati + log_tpl + log_reddito, 
                 data = dataset, W_dist_listw) 
summary(sem2,Nagelkerke=TRUE)



# SAR2
sar2 <- lagsarlm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
                   internet_ultraveloce + laureati + log_tpl + log_reddito,
                 data = dataset,         # <-- Devi specificare il nome del dataset
                 listw = W_dist_listw,    # <-- Devi specificare l'oggetto dei pesi
                 tol.solve = 6.2817e-17)
summary(sar2, Nagelkerke=TRUE)
# rho > 0, dipendenza spaziale positiva
#il tasso di mobilità dei laureati di una provincia è influenzato anche dal tasso dei laureati delle province vicine

AIC(sar2)
AIC(sem2)
#aic leggermente migliore del sar


# confrontamo il sar2 con le sue estensioni (sac2 e sdm2)
#SAC2
sac2<-sacsarlm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
                 internet_ultraveloce + laureati + log_tpl + log_reddito,
               data = dataset, W_dist_listw, method="LU")
summary(sac2,Nagelkerke=TRUE)


LR.Sarlm(sac2, sar2)# h0 Il modello corretto è il SAR (lambda = 0)
#p>a accetto h0
# sar2 non deve essere esteso al modello sac2

#SDM
sdm2<-lagsarlm(formula = mobilità_laureati ~ log_brevetti + competenza_numerica + 
                 internet_ultraveloce + laureati + log_tpl + log_reddito,
               data = dataset, W_dist_listw, type = "mixed", tol.solve = 1.10e-20)
summary(sdm2,Nagelkerke=TRUE)

LR.Sarlm(sdm2,sar2)#h0: Il modello corretto è il sar (theta=0)
# p>a si accetta h0
# il modello sar2 non deve essere esteso a sdm2


# anche con matrice a banda di distanza (100km) il modello sar non viene esteso

# confronto sar e sar2(matrice a banda di distanza)
AIC(sar)
AIC(sar2)
# aic del modello con matrice di contiguità standardizzata è inferiore 
#viene preferitp il modello sar con matrice di contiguità standardizzata









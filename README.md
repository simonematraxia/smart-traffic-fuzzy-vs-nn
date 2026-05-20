# Gestione smart di un’intersezione stradale semaforizzata: confronto tra logica fuzzy e rete neurale supervisionata

**Tesi di Laurea Triennale** – Ingegneria Informatica  
Università degli Studi di Enna "Kore" | A.A. 2024/2025  
Autore: Simone Giovanni Matraxia | Relatore: Prof. Giovanni Pau  
Voto: 98/110

---

## Abstract

La congestione del traffico urbano è un problema che le amministrazioni locali faticano a gestire utilizzando i classici semafori a tempo fisso, a causa della loro intrinseca rigidità. Questo elaborato di tesi affronta la problematica proponendo un sistema di controllo semaforico intelligente e adattivo, capace di reagire in tempo reale ai volumi di traffico. Partendo da un controllore basato su logica Fuzzy, precedentemente sviluppato per un incrocio asimmetrico della città di Caltanissetta, l’architettura è stata evoluta introducendo una Rete Neurale Artificiale (ANN). L’algoritmo di apprendimento supervisionato è stato addestrato sfruttando un ampio dataset estratto dalle simulazioni del sistema esperto originale. L’intero ambiente è stato testato in
MATLAB/Simulink avvalendosi della libreria TrueTime. I risultati dimostrano che la rete neurale riesce ad emulare perfettamente le decisioni logiche del controllore Fuzzy, garantendo gli stessi tempi medi di attesa ma rimuovendo l’enorme limite della calibrazione manuale delle regole, offrendo così una
soluzione altamente migliorabile per le moderne Smart Cities.

---

## Tecnologie
- MATLAB / Simulink
- TrueTime 2.0
- Fuzzy Logic Toolbox
- Neural Network Fitting

## Risultati Principali
- R² della Rete Neurale ≈ 0.992 sul set di test
- Tempi di attesa medi: Fuzzy ~35.8s vs NN ~36.3s (S1/S2)
- La rete neurale elimina la necessità di calibrazione manuale delle regole

## Struttura della Repository
/src → File sorgente MATLAB/Simulink (.m, .slx)

/risultati → Grafici delle prestazioni e metriche

/tesi → Tesi completa in PDF/pptx

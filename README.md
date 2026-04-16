# Smart Traffic Intersection Control: Fuzzy Logic vs Neural Network

**Bachelor's Thesis** – Computer Engineering  
Università degli Studi di Enna "Kore" | A.A. 2024/2025  
Author: Simone Giovanni Matraxia | Supervisor: Prof. Giovanni Pau  
Grade: 98/110

---

## Abstract

Urban traffic congestion remains a persistent challenge for city administrations,
particularly when traditional fixed-time traffic lights are used due to their inherent
rigidity. This thesis investigates the design of an adaptive and intelligent traffic
light control system capable of dynamically responding to real-time traffic conditions.

The study builds upon a previously developed fuzzy-logic controller designed for an
asymmetric intersection in the city of Caltanissetta, Italy. Starting from this
expert-system approach, the work introduces an Artificial Neural Network (ANN) trained
through supervised learning to replicate and potentially enhance the decision-making
process of the fuzzy controller.

Experimental results show that the trained neural network successfully reproduces
the behavior of the fuzzy controller while eliminating the need for manual rule
calibration. This data-driven approach improves system scalability and adaptability,
offering a promising solution for intelligent traffic management within modern smart
city infrastructures.

---

## Technologies
- MATLAB / Simulink
- TrueTime 2.0
- Fuzzy Logic Toolbox
- Neural Network Fitting (Levenberg-Marquardt)

## Key Results
- Neural Network R² ≈ 0.992 on test set
- Average wait times: Fuzzy ~35.8s vs NN ~36.3s (S1/S2)
- NN eliminates manual rule calibration

## Repository Structure
/src → MATLAB/Simulink source files (.m, .slx)

/results → Performance plots and metrics

/thesis → Full thesis PDF

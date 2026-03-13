# Fortran95 + F90GL UI API (Vision & Concept)

Cette section accueillera une API moderne permettant de créer des interfaces graphiques en Fortran95 en s’appuyant sur **f90GL** (OpenGL pour Fortran).  
L’objectif est d’offrir une couche simple, intuitive et portable pour concevoir des applications graphiques, des outils internes, des dashboards et des interfaces interactives — tout en restant 100% Fortran.

## 🎯 Vision
Créer une API haut niveau qui permet d’écrire des interfaces graphiques comme ceci :

```fortran
call UI_Begin("Ma Fenêtre", width=800, height=600)

call UI_Label("Température actuelle : 22.5°C")
if (UI_Button("Rafraîchir")) then
    call RefreshData()
end if

call UI_End()

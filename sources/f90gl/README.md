# f90GL — Sources Officielles (Intégration GF‑Fortran‑SDK)

Ce dossier contient les **sources originales** de f90GL, un ensemble de modules Fortran 90/95 fournissant des interfaces vers OpenGL, GLU et GLUT.  
Ces fichiers proviennent directement de la distribution officielle du NIST et sont intégrés ici afin d’assurer une version stable, contrôlée et portable pour le SDK.

## 📦 Contenu du dossier

- `unix/`  
  Sources et fichiers spécifiques aux environnements Unix/Linux.

- `windows/`  
  Sources et fichiers spécifiques à la compilation sous Windows.

- `license-nist.txt`  
  Licence officielle du NIST pour f90GL (domaine public aux États‑Unis).  
  Ce fichier doit être conservé tel quel conformément aux exigences de redistribution.

- `nist-install-instruction.pdf`  
  Documentation originale fournie par le NIST expliquant la structure du projet et les instructions d’installation.

## 🎯 Rôle dans GF‑Fortran‑SDK

f90GL est utilisé comme **base graphique** pour la future API UI du SDK.  
Il permet :

- la création de fenêtres OpenGL  
- la gestion des événements clavier/souris  
- le rendu 2D/3D  
- l’intégration d’une interface utilisateur personnalisée

Le SDK fournira une couche d’abstraction moderne par‑dessus f90GL afin de simplifier son utilisation dans des projets Fortran95.

## 🔧 Compilation

GF‑Fortran‑SDK ne requiert pas que l’utilisateur final compile f90GL.  
Des versions précompilées seront fournies dans :


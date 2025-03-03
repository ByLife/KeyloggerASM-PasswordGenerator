# Keylogger en Assembly x86_64

Ce programme est un keylogger écrit en Assembly NASM pour les systèmes Linux (architecture x86_64). Il capture les frappes clavier et les enregistre dans un fichier de log avec horodatage précis, tout en fonctionnant en arrière-plan.

## Table des matières

- [Fonctionnalités](#fonctionnalités)
- [Structure du code](#structure-du-code)
  - [Section .data](#section-data)
  - [Section .bss](#section-bss)
  - [Section .text et routines principales](#section-text-et-routines-principales)
- [Schéma fonctionnel](#schéma-fonctionnel)
- [Compilation](#compilation)
- [Exécution et utilisation](#exécution-et-utilisation)
  - [Démarrage du keylogger](#démarrage-du-keylogger)
  - [Arrêt du keylogger](#arrêt-du-keylogger)
  - [Format du fichier de log](#format-du-fichier-de-log)
- [Détails techniques](#détails-techniques)
  - [Fonctionnement en arrière-plan](#fonctionnement-en-arrière-plan)
  - [Configuration du terminal](#configuration-du-terminal)
  - [Contrôle du keylogger](#contrôle-du-keylogger)
  - [Appels système utilisés](#appels-système-utilisés)
- [Considérations éthiques et juridiques](#considérations-éthiques-et-juridiques)

## Fonctionnalités

Le keylogger offre les fonctionnalités suivantes :

- **Capture des frappes clavier** : Enregistre toutes les touches pressées sur le clavier.
- **Horodatage précis** : Chaque frappe est enregistrée avec un timestamp.
- **Fonctionnement en arrière-plan** : Utilise le mécanisme de fork pour créer un processus détaché.
- **Mécanisme d'arrêt propre** : Possibilité d'arrêter le keylogger via un fichier de contrôle.
- **Restauration des paramètres du terminal** : Restaure les paramètres originaux du terminal à la sortie.

## Structure du code

### Section .data

Cette section contient les constantes et les chaînes de caractères utilisées par le programme :

- **Chemins de fichiers**
  - `log_file` : Chemin du fichier de journalisation ("keylog.txt").
  - `ctrl_file` : Chemin du fichier de contrôle ("k.ctrl").

- **Messages et constantes**
  - `start_msg` : Message de démarrage.
  - Constantes pour les descripteurs standard (STDIN, STDOUT).
  - Constantes pour les opérations sur le terminal (TCGETS, TCSETS).

### Section .bss

Cette section réserve la mémoire pour les variables non initialisées :

- `termios` et `orig_termios` : Stockage des paramètres du terminal.
- `buf` : Buffer d'entrée pour la lecture clavier.
- `time_buf` : Buffer pour formater l'horodatage.
- `tspec` : Structure pour l'appel `clock_gettime`.

### Section .text et routines principales

- **Point d'entrée (`_start`)**
- **Gestion des processus parent/enfant**
- **Boucle principale de capture**
- **Fonctions de vérification et de sortie**

## Schéma fonctionnel

Le schéma ci-dessous illustre les interactions entre les différentes fonctions du keylogger :

![keylog_schema](https://github.com/user-attachments/assets/1a57a0ea-60f8-44b4-998a-337c5c854c32)


### Explication du schéma

Le flux d'exécution du programme peut être divisé en plusieurs phases :

1. **Initialisation** : Le programme démarre avec la fonction `_start` qui :
   - Crée et initialise le fichier de contrôle
   - Ouvre le fichier de log
   - Écrit un message de démarrage dans le log
   - Réalise un fork pour créer un processus enfant

2. **Séparation des processus** :
   - Le processus parent se termine immédiatement (sortie)
   - Le processus enfant devient le keylogger actif et continue l'exécution

3. **Configuration du terminal** (processus enfant uniquement) :
   - Crée une nouvelle session avec `setsid`
   - Récupère et sauvegarde les paramètres actuels du terminal
   - Modifie ces paramètres pour désactiver l'écho et le mode canonique
   - Applique les nouveaux paramètres

4. **Boucle principale** (`main_loop`) qui exécute séquentiellement :
   - **Vérification** : Contrôle l'état du fichier de contrôle pour savoir si le keylogger doit s'arrêter
   - **Lecture** : Capture une touche pressée
   - **Enregistrement** : Enregistre la touche avec horodatage dans le fichier de log

5. **Nettoyage et sortie** (`cleanup_exit` et `exit`) :
   - Restaure les paramètres originaux du terminal
   - Ferme proprement les fichiers ouverts
   - Termine le programme

## Compilation

Pour compiler le keylogger, assurez-vous d'avoir NASM et ld installés sur votre système Linux :

```bash
nasm -f elf64 keylogger.asm -o keylogger.o
ld keylogger.o -o keylogger
```

## Exécution et utilisation

### Démarrage du keylogger

Lancez simplement l'exécutable depuis un terminal :

```bash
./keylogger
```

Le programme se lancera en arrière-plan, créera un fichier `keylog.txt` et commencera à enregistrer les frappes clavier.

### Arrêt du keylogger

Pour arrêter proprement le keylogger, écrivez la valeur 1 dans le fichier de contrôle :

```bash
echo -n -e "\x01" > k.ctrl
```

Cette commande signale au keylogger qu'il doit s'arrêter, restaurer les paramètres du terminal et terminer proprement son exécution.

### Format du fichier de log

Le fichier `keylog.txt` contient les entrées au format suivant :

```
[timestamp] | [touche]
```

Exemple :
```
00000000001675842036 | a
00000000001675842038 | b
00000000001675842045 | c
```

## Détails techniques

### Fonctionnement en arrière-plan

Le keylogger utilise `fork()` pour créer un processus enfant, puis `setsid()` pour détacher ce processus du terminal. Cela permet au keylogger de continuer à fonctionner même après la fermeture du terminal qui l'a lancé.

### Configuration du terminal

Le programme modifie les paramètres du terminal pour :
- Désactiver l'écho (les touches pressées ne sont pas affichées)
- Désactiver le mode canonique (lecture immédiate sans attendre Entrée)
- Configurer la lecture caractère par caractère

### Contrôle du keylogger

Le mécanisme de contrôle utilise un fichier simple (`k.ctrl`) :
- Au démarrage, le keylogger écrit 0 dans ce fichier
- Pour arrêter le keylogger, un autre processus doit écrire 1 dans ce fichier
- Le keylogger vérifie périodiquement ce fichier pour savoir s'il doit s'arrêter

### Appels système utilisés

| Syscall | Numéro | Description |
|---------|--------|-------------|
| sys_open | 2 | Ouverture des fichiers (log et contrôle) |
| sys_close | 3 | Fermeture des fichiers |
| sys_write | 1 | Écriture dans les fichiers et à l'écran |
| sys_read | 0 | Lecture depuis le terminal et les fichiers |
| sys_fork | 57 | Création du processus enfant |
| sys_setsid | 112 | Création d'une nouvelle session |
| sys_ioctl | 16 | Manipulation des paramètres du terminal |
| sys_clock_gettime | 228 | Récupération de l'horodatage précis |
| sys_exit | 60 | Terminaison du programme |

## Considérations éthiques et juridiques

Ce keylogger est fourni à des fins éducatives uniquement pour comprendre les mécanismes de programmation système en Assembly. L'utilisation de ce programme pour enregistrer les frappes clavier d'autres personnes sans leur consentement explicite peut être :

1. Illégale dans de nombreuses juridictions
2. Une violation des politiques de confidentialité et de sécurité
3. Une atteinte à la vie privée

Assurez-vous de n'utiliser ce code que sur vos propres systèmes ou avec l'autorisation explicite des propriétaires des systèmes concernés.

# Générateur de mots de passe

Ce programme, écrit en NASM pour Linux (x86_64), permet de générer des mots de passe selon plusieurs niveaux de complexité et de sauvegarder les mots de passe générés dans un fichier (le vault). Le programme propose également une interface interactive avec plusieurs commandes.

## Table des matières

- [Fonctionnalités](#fonctionnalités)
- [Structure du code](#structure-du-code)
- [Prérequis](#prérequis)
- [Compilation](#compilation)
- [Exécution](#exécution)
- [Commandes disponibles](#commandes-disponibles)
- [Gestion du Vault](#gestion-du-vault)
- [Remarques et améliorations possibles](#remarques-et-améliorations-possibles)

## Fonctionnalités

- **Génération de mots de passe :**  
  Le programme peut générer différents types de mots de passe :
  - **Simple :** 8 caractères (chiffres et lettres)
  - **Medium :** 10 caractères (chiffres, lettres et caractères spéciaux)
  - **Hardcore :** 20 caractères (chiffres, lettres et caractères spéciaux)
  - **Custom :** Génération sur mesure selon la longueur et les types de caractères choisis

- **Sauvegarde persistante (Vault) :**  
  Après chaque génération, l'utilisateur peut choisir de sauvegarder le mot de passe avec un nom associé. La sauvegarde est effectuée à la fois en mémoire et dans un fichier `vault.txt`, permettant de retrouver les entrées entre différentes exécutions du programme.

- **Affichage et suppression du Vault :**  
  - La commande `vault` affiche la liste des mots de passe sauvegardés.
  - La commande `vault delete` permet de vider le fichier de sauvegarde et de réinitialiser le vault en mémoire.

## Structure du code

Le code source est organisé en plusieurs sections :

- **.data :**  
  Contient les chaînes de caractères (messages, invites, ensembles de caractères, etc.) ainsi que les constantes utilisées (longueurs, flags pour les appels système, etc.).

- **.bss :**  
  Réserve des zones mémoire pour le buffer d'entrée, les buffers des différents mots de passe, le stockage du vault et d'autres variables (par exemple, le seed pour la génération aléatoire).

- **.text :**  
  Contient le code exécutif avec :
  - La routine `load_vault` qui charge le contenu de `vault.txt` dans la mémoire au démarrage.
  - La boucle principale (`main_loop`) qui affiche le prompt, lit la commande utilisateur et oriente vers la fonctionnalité correspondante.
  - Des routines de génération de mots de passe (`gen_simple`, `gen_medium`, `gen_hardcore`, `gen_custom`).
  - La routine `vault_prompt` qui demande si l'utilisateur souhaite sauvegarder le mot de passe généré, puis enregistre l'entrée dans le vault (en mémoire et dans le fichier).
  - La routine `vault_save_to_file` qui gère l'écriture en mode append dans le fichier.
  - La routine `vault_delete` qui vide le fichier et réinitialise la zone mémoire du vault.
  - La routine `show_vault` pour afficher le contenu du vault.
  - La routine `display_result` pour afficher le mot de passe généré.

## Prérequis

- Un système d'exploitation Linux (x86_64)
- NASM (Netwide Assembler)
- Linker (ld) pour créer l'exécutable

## Compilation

Pour compiler le programme, utilisez NASM avec le format ELF64, puis liez l'objet généré avec le linker. Par exemple :

```bash
nasm -f elf64 generateur.asm -o generateur.o
ld generateur.o -o generateur

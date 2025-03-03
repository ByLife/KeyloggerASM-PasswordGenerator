# Générateur de mots de passe avec gestion persistante du Vault

Ce programme, écrit en NASM pour Linux (architecture x86_64), permet de générer des mots de passe selon différents critères et de les sauvegarder de manière persistante dans un fichier (`vault.txt`). Il propose une interface en ligne de commande interactive offrant plusieurs commandes pour générer, afficher ou vider le vault.

## Table des matières

- [Fonctionnalités](#fonctionnalités)
- [Structure du code](#structure-du-code)
  - [Section .data](#section-data)
  - [Section .bss](#section-bss)
  - [Section .text et les routines principales](#section-text-et-les-routines-principales)
- [Compilation](#compilation)
- [Exécution et utilisation](#exécution-et-utilisation)
  - [Commandes disponibles](#commandes-disponibles)
  - [Gestion du Vault](#gestion-du-vault)
- [Détails techniques](#détails-techniques)
  - [Génération de nombres pseudo-aléatoires](#génération-de-nombres-pseudo-aléatoires)
  - [Appels système utilisés](#appels-système-utilisés)
- [Remarques et améliorations possibles](#remarques-et-améliorations-possibles)

## Fonctionnalités

- **Génération de mots de passe**  
  Le programme propose quatre modes de génération :
  - **Simple** : 8 caractères (lettres majuscules et minuscules, chiffres)
  - **Medium** : 10 caractères (lettres, chiffres et quelques caractères spéciaux)
  - **Hardcore** : 20 caractères (mélange de lettres, chiffres et caractères spéciaux)
  - **Custom** : L'utilisateur peut définir la longueur du mot de passe et choisir d'inclure ou non des minuscules, majuscules, chiffres et caractères spéciaux.

- **Sauvegarde persistante (Vault)**  
  Après la génération d’un mot de passe, le programme propose de le sauvegarder avec un nom. L'entrée sauvegardée est stockée dans une zone mémoire et également ajoutée en fin de fichier (`vault.txt`).  
  Au démarrage, le programme charge le contenu de ce fichier pour pouvoir afficher l’historique des mots de passe sauvegardés.

- **Gestion du Vault**  
  - La commande `vault` affiche l'ensemble des entrées sauvegardées.
  - La commande `vault delete` vide le fichier de sauvegarde et réinitialise le vault en mémoire.

## Structure du code

Le code est divisé en trois sections principales :

### Section .data

Contient les constantes et chaînes de caractères utilisées par le programme, telles que :

- **Messages et invites :**  
  - Message de bienvenue (`welcome_msg`)
  - Liste des commandes disponibles (`commands_msg`)
  - Invite de commande (`prompt_msg`)
  - Messages d'erreur et de succès (par exemple, `success_msg`, `unknown_cmd_msg`)

- **Ensembles de caractères :**  
  - Pour la génération des mots de passe simples, medium et hardcore (`allowed_chars`, `allowed_medium_chars`).

- **Constantes pour la commande Vault :**  
  - Noms de commandes (`vault_str`, `vault_delete_str`)
  - Prompts spécifiques (pour sauvegarder et nommer un mot de passe, `vault_save_prompt` et `vault_name_prompt`)
  - Messages pour afficher le vide du vault (`empty_vault_msg`, `vault_deleted_msg`)

### Section .bss

Réserve de la mémoire pour les variables qui changent pendant l'exécution :

- **Buffers de lecture et de génération :**  
  - `input_buffer` : pour la saisie utilisateur.
  - Buffers pour les mots de passe générés (`simple_password_buffer`, `medium_password_buffer`, `hardcore_password_buffer`, `custom_password_buffer`).

- **Variables de génération et stockage :**  
  - `seed` : utilisé pour la génération pseudo-aléatoire.
  - Zone de stockage du vault (`vault_storage`) et variable d'offset (`vault_offset`) pour gérer l'ajout des nouvelles entrées.
  - Buffers pour le nom d'entrée et les informations sur le dernier mot de passe généré (`name_input`, `last_password_ptr`, `last_password_len`).

### Section .text et les routines principales

Cette section contient le code exécutable organisé en plusieurs routines :

- **`_start`**  
  Le point d'entrée du programme. Il charge le contenu du fichier vault via `load_vault`, affiche le message de bienvenue et la liste des commandes, puis entre dans la boucle principale (`main_loop`).

- **Boucle principale (`main_loop`)**  
  Affiche une invite, lit la commande de l'utilisateur et oriente vers la fonction appropriée en effectuant des comparaisons de chaînes.

- **Routines de génération de mots de passe :**  
  - `gen_simple`, `gen_medium`, `gen_hardcore` et `gen_custom` : Chacune de ces routines génère un mot de passe en fonction des paramètres souhaités. La génération utilise une méthode de type LCG (Linear Congruential Generator) combinée avec la valeur de `rdtsc` pour obtenir une source d'aléa.

- **Gestion du Vault :**  
  - `vault_prompt` : Après génération, cette routine demande si l'utilisateur souhaite sauvegarder le mot de passe. En cas de réponse positive, le programme demande un nom et construit une entrée au format `[nom] : [mot de passe]\n`. Cette entrée est ajoutée à la zone mémoire du vault et ensuite écrite dans le fichier via `vault_save_to_file`.
  - `vault_save_to_file` : Ouvre le fichier `vault.txt` en mode append et écrit l'entrée sauvegardée. Les valeurs nécessaires (pointeur et taille) sont préservées dans des registres pour éviter d'être écrasées par l'appel système.
  - `vault_delete` : Permet de vider le fichier en l'ouvrant en mode écriture avec troncation (O_TRUNC) et réinitialise le vault en mémoire. Un message de confirmation est affiché.
  - `show_vault` et `vault_display` : Affichent le contenu du vault stocké en mémoire.

- **Affichage du résultat (`display_result`)**  
  Affiche le mot de passe généré ainsi que quelques sauts de ligne pour une meilleure lisibilité.

## Compilation

Pour compiler ce programme, utilisez NASM pour assembler le fichier source en format ELF64, puis liez l'objet généré avec ld :

```bash
nasm -f elf64 generateur.asm -o generateur.o
ld generateur.o -o generateur

# Documentation Technique : Générateur de Mots de Passe en NASM

## Introduction

Ce programme écrit en NASM pour Linux (x86_64) permet de générer des mots de passe sécurisés et de les sauvegarder de manière persistante dans un fichier `vault.txt`. Il fournit une interface interactive en ligne de commande où l'utilisateur peut générer des mots de passe selon différents critères, consulter un historique des mots de passe enregistrés et les supprimer si nécessaire.

Le programme est divisé en plusieurs sections : gestion des données en mémoire et dans un fichier, génération de mots de passe avec un algorithme pseudo-aléatoire, et interaction avec l'utilisateur pour le stockage et la récupération des mots de passe.

## Structure du Programme

Le programme est divisé en trois sections principales :

1. **La section `.data`**, où sont stockées toutes les constantes et chaînes de caractères utilisées.
2. **La section `.bss`**, où sont déclarées les variables non initialisées nécessaires pour la gestion des mots de passe et du Vault.
3. **La section `.text`**, qui contient le code exécutable et est organisée en plusieurs sous-routines pour assurer les différentes fonctionnalités du programme.

### Gestion des chaînes de caractères et des messages

Dans la section `.data`, plusieurs messages sont définis pour afficher des instructions et des confirmations à l’utilisateur. Par exemple, `welcome_msg` contient le message d'accueil affiché au lancement du programme, tandis que `commands_msg` liste toutes les commandes disponibles.

On trouve aussi des chaînes contenant les caractères autorisés pour générer les mots de passe (`allowed_chars`, `allowed_medium_chars`), ainsi que des messages liés à la gestion du Vault (`vault_save_prompt`, `vault_deleted_msg`).

### Variables dynamiques et buffers

Dans la section `.bss`, le programme réserve des zones mémoire pour stocker temporairement les mots de passe générés et la liste des mots de passe enregistrés. Les variables importantes incluent :

- `input_buffer`, qui stocke la commande saisie par l’utilisateur.
- `simple_password_buffer`, `medium_password_buffer` et `hardcore_password_buffer`, qui contiennent les mots de passe générés.
- `vault_storage`, qui stocke le contenu du Vault en mémoire avant de l’écrire dans le fichier `vault.txt`.

## Fonctionnalités et Explication des Fonctions

### Chargement du Vault (`load_vault`)

Cette fonction est appelée au démarrage du programme. Elle tente d'ouvrir le fichier `vault.txt` en lecture seule. Si le fichier existe, son contenu est lu et stocké dans `vault_storage`, et la taille des données est sauvegardée dans `vault_offset`. Si le fichier n'existe pas encore, la fonction termine simplement son exécution.

![image](https://github.com/user-attachments/assets/7cf21d43-654b-444e-aee4-ee115f25b12e)


### Boucle principale (`main_loop`)

Le programme entre dans une boucle infinie où il affiche un message d'invite (`prompt_msg`), puis lit la commande entrée par l'utilisateur. La commande est ensuite comparée aux chaînes définies (`simple_str`, `medium_str`, `vault_str`, etc.), et la fonction correspondante est exécutée.

Si l'utilisateur entre une commande inconnue, un message d'erreur est affiché, et le programme continue à attendre une nouvelle entrée.

### Génération de mots de passe (`gen_simple`, `gen_medium`, `gen_hardcore`, `gen_custom`)

Chaque fonction de génération de mots de passe utilise une méthode similaire pour produire une chaîne de caractères aléatoire. La fonction `rdtsc` est utilisée pour obtenir une graine aléatoire basée sur le compteur de cycles du processeur. Un générateur congruentiel linéaire (LCG) est ensuite appliqué pour générer un index permettant de sélectionner un caractère aléatoire parmi un ensemble défini.

Exemple pour `gen_simple` :

![image](https://github.com/user-attachments/assets/21b9892b-69a6-42fe-a60c-a64b73326d2b)


Un caractère est sélectionné à chaque itération et stocké dans `simple_password_buffer`. Une fois la boucle terminée, le mot de passe est affiché et sauvegardé si l'utilisateur le souhaite.

### Gestion du Vault (`vault_prompt`, `vault_save_to_file`, `vault_delete`, `show_vault`)

Lorsque l'utilisateur choisit de sauvegarder un mot de passe, la fonction `vault_prompt` lui demande un nom. Le mot de passe est ensuite ajouté au `vault_storage` en mémoire et écrit dans `vault.txt` via `vault_save_to_file`.

Si l'utilisateur exécute `vault`, la fonction `show_vault` affiche le contenu du Vault en mémoire.

Si `vault delete` est utilisé, `vault_delete` ouvre `vault.txt` en mode écriture avec troncation (`O_TRUNC`), effaçant ainsi tout son contenu. La mémoire utilisée pour `vault_storage` est également réinitialisée.

### Sortie du programme (`exit_program`)

Lorsque l'utilisateur entre `exit`, le programme effectue un appel système `sys_exit` pour terminer proprement son exécution.

![image](https://github.com/user-attachments/assets/ef3abe7f-a0db-453a-8373-58bbd6cce147)



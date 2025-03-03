# Keylogger en Assembleur

## À propos du projet

Ce projet est un keylogger simple mais efficace écrit en langage assembleur x86_64 pour les systèmes Linux. Il capture les frappes clavier en modifiant les paramètres du terminal et enregistre chaque touche dans un fichier journal avec un horodatage précis.

## Fonctionnalités

- Capture de toutes les touches saisies
- Enregistrement dans un fichier journal (keylog.txt)
- Horodatage précis pour chaque frappe
- Exécution en arrière-plan (processus détaché)
- Mécanisme de contrôle pour l'arrêt propre du keylogger

## Architecture technique

Le keylogger utilise plusieurs fonctionnalités systèmes Linux pour accomplir sa tâche:

- Appels système Linux pour la manipulation de fichiers
- Contrôle du terminal via ioctl
- Fork pour créer un processus enfant détaché
- Manipulation des paramètres du terminal pour capturer les touches sans écho
- Horodatage précis via clock_gettime

## Compilation

Pour compiler ce programme, utilisez NASM et ld:

```bash
# Compilation avec NASM
nasm -f elf64 keylogger.asm -o keylogger.o

# Linkage
ld keylogger.o -o keylogger
```

## Utilisation

Pour lancer le keylogger:

```bash
./keylogger
```

Le programme s'exécutera en arrière-plan et commencera à enregistrer les frappes clavier dans le fichier `keylog.txt`.

Pour arrêter le keylogger:

```bash
echo "1" > k.ctrl
```

## Structure des fichiers

- `keylogger.asm` - Code source du keylogger
- `keylog.txt` - Fichier de sortie où les frappes sont enregistrées
- `k.ctrl` - Fichier de contrôle pour arrêter proprement le keylogger

## Format du journal

Les entrées dans le fichier journal sont formatées comme suit:

```
[timestamp] | [key]
```

Où `timestamp` est l'horodatage Unix en secondes et `key` est le caractère saisi.

## Remarques importantes

Ce projet est développé uniquement à des fins éducatives pour comprendre:
- La programmation en assembleur
- Les interactions avec le système d'exploitation Linux
- La manipulation des entrées/sorties brutes

**Attention**: L'utilisation d'un keylogger sans le consentement explicite de l'utilisateur est illégale et contraire à l'éthique. Utilisez ce code uniquement sur vos propres systèmes et avec votre propre consentement.

## Auteurs

- Luc Martin
- Léo HAIDAR    

## Licence

Ce projet est fourni à titre éducatif seulement. Aucune licence explicite n'est fournie.

---

© 2025 - Luc Martin & Léo HAIDAR
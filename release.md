# Paquets Python (source et wheel)

À la racine du projet :

    # Source
    python setup.py sdist
    # Wheel
    python setup.py bdist_wheel

Avec le makefile : ``make dist wheel``.

# Paquet Debian

TODO

# Paquet MacOS

TODO

# Installateur Windows

Commencer par générer le pauet `wheel` (voir ci-dessus), puis dans le répertoire ``data/windows/`` :

    python -m nsist installer.cfg


Avec le makefile : ``make exe``.

*Remarque : En théorie, ceci fonctionne aussi depuis un environnement GNU/Linux. En pratique, mieux vaut redémarrer sous Windows (ou utiliser une machine virtuelle) pour vérifier que l'installateur fonctionne.*

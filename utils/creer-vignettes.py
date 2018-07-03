#!/usr/bin/env python3

# pylint: disable=invalid-name

"""Crée et met à jour les vignettes des exercices."""

import gettext
import hashlib
import json
import logging
import os
import shutil
import sys
import tempfile
from subprocess import call
from contextlib import contextmanager

from pyromaths.ex import ExerciseBag

# Définition de `_()` comme la fonction identité.
# Pour le moment, les vignettes des exercices ne sont pas traduites.
gettext.install('pyromaths')

ROOTDIR = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))

sys.path.insert(0, os.path.realpath(ROOTDIR))
# pylint: disable=wrong-import-position
import pyromaths
from pyromaths.Values import data_dir, configdir
from pyromaths.outils.System import Fiche

THUMBDIR = os.path.join(data_dir(), "ex", "img")
MD5PATH = os.path.join(THUMBDIR, "md5sum.json")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(message)s',
    )

@contextmanager
def md5file():
    """Contexte pour lire et écrire les md5sum des exercices."""
    # Création du fichier s'il n'existe pas déjà.
    if not os.path.exists(MD5PATH):
        with open(MD5PATH, mode="w") as fichier:
            json.dump({}, fichier)

    logging.info("Lecture du fichier '%s'.", MD5PATH)
    with open(MD5PATH, mode="r") as fichier:
        md5sums = json.loads(fichier.read())

    yield md5sums

    logging.info("Écriture du fichier '%s'.", MD5PATH)
    with open(MD5PATH, mode="w") as fichier:
        json.dump(md5sums, fichier, sort_keys=True, indent=4)

def create_thumbnail(exo, tempdir):
    """Crée la vignette de l'exercice"""
    outfile = exo.thumb()

    logging.info("Compilation de l'exercice.")
    thumbnail = exo(0).generate(corrige=False, dir=tempdir)

    logging.info("Extraction de la vignette.")
    call([
        "convert",
        "-density", "288",
        thumbnail,
        "-resize", "25%",
        "-crop", "710x560+0+85",
        "-flatten", "-trim",
        os.path.join(tempdir, "thumb.png"),
        ])

    logging.info("Appel de `pngnq` sur la vignette.")
    call([
        "pngnq", "-f", "-s1", "-n32", os.path.join(tempdir, "thumb.png"),
        ])
    shutil.copyfile(os.path.join(tempdir, "thumb-nq8.png"), outfile)

    logging.info("Optimisation de la vignette.")
    call(args=["optipng", "-o7", outfile])

def md5sum(exo):
    """Calcule et renvoit le hash md5sum de l'énoncé 0 de l'exercice."""
    return hashlib.md5(
        exo(0).tex_statement()
        .encode(errors="backslashreplace")
        ).hexdigest()

def main(tempdir):
    """Fonction principale"""
    with md5file() as md5sums:
        for exo in ExerciseBag().values():
            logging.info("Exercice '%s'.", exo.name())
            if md5sums.get(exo.name(), "0") == md5sum(exo):
                logging.info("L'exercice n'a pas été modifié.")
                continue
            create_thumbnail(exo, tempdir)
            md5sums[exo.name()] = md5sum(exo)

if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="pyromaths") as tempdir:
        main(tempdir)

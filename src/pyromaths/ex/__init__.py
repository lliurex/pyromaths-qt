#!/usr/bin/env python3

import collections
import importlib
import inspect
import logging
import operator
import os
import pkgutil
import sys
import types

from ..outils import jinja2

class TexExercise:
    """Exercise with TeX support."""

    @classmethod
    def name(cls):
        return cls.__name__

    @classmethod
    def description(cls):
        return cls.__doc__.splitlines()[0]

    @classmethod
    def thumb(cls):
        from pyromaths.Values import data_dir
        return os.path.join(data_dir(), 'ex', 'img', "%s.png" % cls.name())

    def tex_statement(self):
        ''' Return problem statement in TeX format. '''
        raise NotImplementedError()

    def tex_answer(self):
        ''' Return full answer in TeX format. '''
        raise NotImplementedError()


class LegacyExercise(TexExercise):
    """Base class for legacy format exercise proxies.

    This class is deprecated. Do not use it to write new exercises.
    """

    def __init__(self):
        self.stat, self.ans = self.__class__.function()

    def tex_statement(self):
        return "\n".join(self.stat)

    def tex_answer(self):
        return "\n".join(self.ans)

def __module(filename):
    """Expect an absolute path, subpath of this module's path. Return a relative path."""
    # Get root of this application
    root = '/'.join(__file__.split('/')[:-len(__name__.split('.')) - 1])
    # Get filename, relative to said root
    relative = filename[len(root)+1:]
    # Remove extension
    relative = relative[:-len('.py')]
    # Turn file system path into python package
    relative = relative.replace('/', '.')

    return relative

def __import(name=__name__, parent=None):
    ''' Import 'name' from 'parent' package. '''
    if not isinstance(name, str):
        name = name.__name__
    # parent is None: assume 'name' is a package name
    # hack tout moche pour l'import des exercices dans la version Windows de Pyromaths :
    # Les modules sixiemes, quatriemes doivent être appelés avec le chemin complet,
    # alors que les exercices cinquiemes.aires ne doivent être appelés qu'ainsi.
    if "." not in name and hasattr(sys, "frozen"): name = "pyromaths.ex." + name
    if parent is None: parent = name
    elif not isinstance(parent, str):
        # assume 'parent' is a package instance
        parent = parent.__name__
    return importlib.import_module(name)
    # return __import__(name, fromlist=parent)

def _iter_pkg_exercises(pkg):
    ''' List exercises in 'pkg' modules. '''
    # level defaults to description, then unknown
    if 'level' not in dir(pkg): pkg.level = "Inconnu"
    for _, name, ispkg in pkgutil.iter_modules(pkg.__path__, pkg.__name__ + '.'):
        # skip packages
        if ispkg: continue;
        # import module
        mod = __import(name, pkg)
        # search exercises in module
        for name in dir(mod):
            cls = getattr(mod, name)
            if name.startswith("_"):
                continue
            if not isinstance(cls, type):
                continue
            if not issubclass(cls, TexExercise):
                continue
            if cls.__module__ == "pyromaths.ex":
                continue
            yield cls

def _subpackages(pkg):
    ''' List 'pkg' sub-packages. '''
    for _, name, ispkg in pkgutil.iter_modules(pkg.__path__, pkg.__name__ + '.'):
        # skip modules
        if not ispkg: continue;
        yield __import(name, pkg)

def _iter_exercises(pkg=None):
    """Iterator over existing exercises"""
    if pkg is None:
        pkg = __import()
    yield from _iter_pkg_exercises(pkg)

    # load sub-packages
    for sub in _subpackages(pkg):
        yield from _iter_exercises(sub)

NIVEAUX = [
    "Sixième",
    "Cinquième",
    "Quatrième",
    "Troisième",
    "Seconde",
    "1èreS",
    "Term STMG",
    "Term S",
    "Term ES",
    # "exemple",
    ]

class ExerciseBag(collections.UserDict):
    """Classe regroupant tous les exercices.

    Cette classe est la sous-classe d'un dictionnaire :
    - clef: le nom (:type:`str`) des exercices ;
    - valeur: l'exercice (:type:`TexExercise`).

    Des méthodes permettent d'accéder à ces exercices avec d'autres présentations.
    """

    def __init__(self):
        super().__init__()
        for exo in _iter_exercises():
            if exo.name() in self:
                logging.error(
                    "Deux exercices portent le même nom '%s': %s et %s.",
                    exo.name(),
                    exo,
                    self[exo.name()],
                    )
            self[exo.name()] = exo

    def dict_levels(self):
        """Renvoit les exercices, comme un dictionnaire classé par niveau.

        - clefs: les niveaux ;
        - valeurs: l'ensemble des exercices de ce niveau.

        Remarque : Des exercices qui appartiennent à plusieurs niveaux peuvent
        apparaître plurieurs fois.
        """
        levels = collections.defaultdict(set)
        for exo in self.values():
            for lvl in exo.tags:
                levels[lvl].add(exo)
        return levels

    def sorted_levels(self):
        """Renvoit les exercices, sous la forme d'une liste triée par niveau.

        Chaque élément de la liste est lui-même une liste ``[niveau, exercices]``, où :
        - ``niveau`` : est le niveau (chaîne de caractères) ,
        - ``exercices`` : est la liste triée des exercices de ce niveau.

        Le tri par niveau est un tri logique pour un humain (sixième, puis cinquième, etc.).
        """
        levels = self.dict_levels()
        return [
            [niveau, sorted(levels[niveau], key=operator.methodcaller("name"))]
            for niveau in NIVEAUX
            ]

################################################################################
# Exercices créés à partir de templates Jinja2

def templatedir():
    from pyromaths import Values
    return os.path.join(
        Values.data_dir(),
        "ex",
        "templates",
        )

class Jinja2Exercise(TexExercise):
    """Exercice utilisant un template jinja2."""

    def __init__(self):
        super().__init__()
        self.context = {}

    @property
    def environment(self):
        """Création de l'environnement Jinja2, duquel sera chargé le template."""
        return jinja2.LatexEnvironment(
            loader=jinja2.FileSystemLoader(templatedir())
        )

    @property
    def statement_name(self):
        """Nom du fichier de l'énoncé (sans le répertoire)."""
        return os.path.join("{}-statement.tex".format(self.__class__.__name__))

    @property
    def answer_name(self):
        """Nom du fichier du corrigé (sans le répertoire)."""
        return os.path.join("{}-answer.tex".format(self.__class__.__name__))

    def tex_statement(self):
        """Génération de l'énoncé"""
        return self.environment.get_template(self.statement_name).render(self.context)

    def tex_answer(self):
        """Génération du corrigé"""
        return self.environment.get_template(self.answer_name).render(self.context)


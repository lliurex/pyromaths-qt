#!/usr/bin/env python3

# Pyromaths
# Un programme en Python qui permet de créer des fiches d'exercices types de
# mathématiques niveau collège ainsi que leur corrigé en LaTeX.
# Copyright (C) 2006 -- Jérôme Ortais (jerome.ortais@pyromaths.org)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#

import sys, os, codecs
from re import findall
from ..outils import jinja2

#==============================================================
#        Gestion des extensions de fichiers
#==============================================================
def supprime_extension(filename, ext):
    """supprime l'éventuelle extension ext du nom de fichier filename.
    ext est de la forme '.tex'"""
    if os.path.splitext(filename)[1].lower():
        return os.path.splitext(filename)[0]
    return filename

def ajoute_extension(filename, ext):
    """ajoute si nécessaire l'extension ext au nom de fichier filename.
    ext est de la forme '.tex'"""
    if os.path.splitext(filename)[1].lower() == ext:
        return filename
    return filename + ext

#==============================================================
#        Créer et lance la compilation des fichiers TeX
#==============================================================
def _preprocess_pipe(filename, pipe):
    """Exécute chacune des commandes de `pipe` sur `filename`.

    :param str filename: Nom du fichier LaTeX qui va être compilé.
    :param list pipe: Liste de commandes à appliquer, sous la forme de chaînes
        de caractères. Si ces chaînes contiennent `{}`, ceci est remplacé par
        le nom du fichier ; sinon, il est ajouté à la fin de la commande. Cet
        élément peut aussi être `None`, auquel cas il correspond à une liste
        vide.
    """
    from subprocess import call
    if pipe is None:
        pipe = []
    for command in pipe:
        formatted = command.format(filename)
        if formatted == command:
            formatted = '{} {}'.format(command, filename)
        call(formatted, env=os.environ, shell=True)

def creation(parametres):
    """Création et compilation des fiches d'exercices.

    parametres = {'fiche_exo': f0,
                  'fiche_cor': f1,
                  'liste_exos': self.lesexos,
                  'creer_pdf': self.checkBox_create_pdf.checkState(),
                  'creer_unpdf': self.checkBox_unpdf.isChecked() and self.checkBox_unpdf.isEnabled(),
                  'titre': unicode(self.lineEdit_titre.text()),
                  'niveau': unicode(self.comboBox_niveau.currentText()),
                }
    """

    environment = jinja2.LatexEnvironment(
        loader=jinja2.FileSystemLoader([
            os.path.join(parametres['datadir'], 'templates'),
            os.path.join(parametres['configdir'], 'templates'),
            ])
    )

    exo = str(parametres['fiche_exo'])
    cor = str(parametres['fiche_cor'])

    with open(exo, mode='w') as exofile:
        exofile.write(environment.get_template(parametres['modele']).render({
            "enonce": True,
            "corrige": parametres['creer_unpdf'],
            "exercices": parametres['liste_exos'],
            "titre": parametres['titre'],
            "niveau": parametres['niveau'],
            "bookmark": r"\currentpdfbookmark{Les énoncés des exercices}{Énoncés}",
            }))
    if parametres['creer_pdf'] and not parametres['creer_unpdf']:
        with open(cor, mode='w') as exofile:
            exofile.write(environment.get_template(parametres['modele']).render({
                "enonce": False,
                "corrige": True,
                "exercices": parametres['liste_exos'],
                "titre": parametres['titre'],
                "niveau": parametres['niveau'],
                "bookmark": r"\currentpdfbookmark{Les énoncés des exercices}{Énoncés}",
                }))

    # Dossiers et fichiers d'enregistrement, définitions qui doivent rester avant le if suivant.
    dir0 = os.path.dirname(exo)
    dir1 = os.path.dirname(cor)
    import socket
    if socket.gethostname() == "sd-94439.pyromaths.org":
        # Chemin complet pour Pyromaths en ligne car pas d'accents
        f0noext = os.path.splitext(exo)[0].encode(sys.getfilesystemencoding())
        f1noext = os.path.splitext(cor)[0].encode(sys.getfilesystemencoding())
    else:
        # Pas le chemin pour les autres, au cas où il y aurait un accent dans
        # le chemin (latex ne gère pas le 8 bits)
        f0noext = os.path.splitext(os.path.basename(exo))[0]
        f1noext = os.path.splitext(os.path.basename(cor))[0]
    if parametres['creer_pdf']:
        from subprocess import call

        _preprocess_pipe(os.path.join(dir0, '{}.tex'.format(f0noext)), parametres.get('pipe', None))
        os.chdir(dir0)
        print(dir0)
        latexmkrc(f0noext)
        log = open('%s-pyromaths.log' % f0noext, 'w')
        if socket.gethostname() == "sd-94439.pyromaths.org":
            os.environ['PATH'] += os.pathsep + "/usr/local/texlive/2016/bin/x86_64-linux"
            call(["latexmk", "-shell-escape", "-silent", "-interaction=nonstopmode", "-output-directory=%s" % dir0, "-pdfps", "%s.tex" % f0noext], env=os.environ, stdout=log)
            call(["latexmk", "-c", "-silent", "-output-directory=%s" % dir0], env=os.environ, stdout=log)
        elif os.name == 'nt':
            call(["latexmk", "%s.tex" % f0noext], env={"PATH": os.environ['PATH'], "WINDIR": os.environ['WINDIR'], 'USERPROFILE': os.environ['USERPROFILE']}, stdout=log)
            call(["latexmk", "-silent", "-c"], env={"PATH": os.environ['PATH'], "WINDIR": os.environ['WINDIR'], 'USERPROFILE': os.environ['USERPROFILE']}, stdout=log)
        else:
            call(["latexmk", "-silent", "%s.tex" % f0noext], stdout=log)
            call(["latexmk", "-silent", "-c"], stdout=log)
        log.close()
        nettoyage(f0noext)
        if not "openpdf" in parametres or parametres["openpdf"]:
            if os.name == "nt":  # Cas de Windows.
                os.startfile('%s.pdf' % f0noext)
            elif sys.platform == "darwin":  # Cas de Mac OS X.
                os.system('open %s.pdf' % f0noext)
            else:
                os.system('xdg-open %s.pdf' % f0noext)

        if parametres['corrige'] and not parametres['creer_unpdf']:
            os.chdir(dir1)
            latexmkrc(f1noext)
            log = open('%s-pyromaths.log' % f1noext, 'w')
            if socket.gethostname() == "sd-94439.pyromaths.org":
                os.environ['PATH'] += os.pathsep + "/usr/local/texlive/2016/bin/x86_64-linux"
                call(["latexmk", "-shell-escape", "-silent", "-interaction=nonstopmode", "-output-directory=%s" % dir1, "-pdfps", "%s.tex" % f1noext], env=os.environ, stdout=log)
                call(["latexmk", "-c", "-silent", "-output-directory=%s" % dir1], env=os.environ, stdout=log)
            elif os.name == 'nt':
                call(["latexmk", "%s.tex" % f1noext], env={"PATH": os.environ['PATH'], "WINDIR": os.environ['WINDIR'], 'USERPROFILE': os.environ['USERPROFILE']}, stdout=log)
                call(["latexmk", "-c"], env={"PATH": os.environ['PATH'], "WINDIR": os.environ['WINDIR'], 'USERPROFILE': os.environ['USERPROFILE']}, stdout=log)
            else:
                call(["latexmk", "-silent", "%s.tex" % f1noext], stdout=log)
                call(["latexmk", "-silent", "-c"], stdout=log)
            log.close()
            nettoyage(f1noext)
            if not "openpdf" in parametres or parametres["openpdf"]:
                if os.name == "nt":  # Cas de Windows.
                    os.startfile('%s.pdf' % f1noext)
                elif sys.platform == "darwin":  # Cas de Mac OS X.
                    os.system('open %s.pdf' % f1noext)
                else:
                    os.system('xdg-open %s.pdf' % f1noext)
        else:
            if os.path.exists('%s-corrige.tex' % f0noext):
                os.remove('%s-corrige.tex' % f0noext)

def latexmkrc(basefilename):
    latexmkrc = open('latexmkrc', 'w')
    latexmkrc.write('$pdf_mode = 2;\n')
    latexmkrc.write('$ps2pdf = "ps2pdf %O %S %D";\n')
    latexmkrc.write('$latex = "latex --shell-escape -silent -interaction=nonstopmode  %O %S";\n')
    latexmkrc.write('sub asy {return system("asy \'$_[0]\'");}\n')
    latexmkrc.write('add_cus_dep("asy","eps",0,"asy");\n')
    latexmkrc.write('add_cus_dep("asy","pdf",0,"asy");\n')
    latexmkrc.write('add_cus_dep("asy","tex",0,"asy");\n')
    #latexmkrc.write('push @generated_exts, \'pre\', \'dvi\', \'ps\', \'auxlock\', \'fdb_latexmk\', \'fls\', \'out\', \'aux\';\n')
    latexmkrc.write('$cleanup_mode = 2;\n')
    #latexmkrc.write('@generated_exts = qw(4ct 4tc acn acr alg aux auxlock bbl dvi eps fls glg glo gls idv idx ind ist lg lof lot nav net out pre ps ptc run.xml snm thm tmp toc vrb xdv xref);')
    latexmkrc.write('$clean_ext .= " %R-?.tex %R-??.tex %R-figure*.dpth %R-figure*.dvi %R-figure*.eps %R-figure*.log %R-figure*.md5 %R-figure*.pre %R-figure*.ps %R-figure*.asy %R-*.asy %R-*_0.eps %R-*.pre";')
    latexmkrc.close()

def nettoyage(basefilename):
    """Supprime les fichiers temporaires créés par LaTeX"""
    #try:
    #    os.remove('latexmkrc')
    #except OSError:
    #        pass)
    if os.path.getsize('{}.pdf'.format(basefilename)) > 1000 :
        for ext in ('.log', '-pyromaths.log'):
            try:
                os.remove(basefilename + ext)
            except OSError:
                pass

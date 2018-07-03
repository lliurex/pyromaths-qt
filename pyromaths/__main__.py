#!/usr/bin/env python3

# Copyright (C) 2016-2018 -- Louis Paternault (spalax@gresille.org)
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

"""Pyromaths command line interface.

To display help:

> python3 -m pyromaths --help
"""
import argparse
import gettext
import logging
import random
import shutil
import subprocess
import sys

from os.path import join, dirname, realpath
import gettext

locale_dir = join(dirname(__file__), '../../../locale/')
locale_dir = realpath(locale_dir)

gettext.bindtextdomain('pyromaths', locale_dir)
gettext.textdomain('pyromaths')
_ = gettext.gettext
# Quick and dirty definition of `_` as the identity function
#gettext.install('pyromaths')

from pyromaths.cli import exercise_argument, PyromathsException
from pyromaths.ex import ExerciseBag
from pyromaths.outils.System import Fiche
from pyromaths.Values import VERSION

# Logging configuration
logging.basicConfig(level=logging.INFO)
LOGGER = logging.getLogger()

def argument_parser():
    """Return an argument parser"""
    parser = argparse.ArgumentParser(
        prog='pyromaths',
        )
    parser.add_argument(
        '-v', '--version',
        action='version',
        version='%(prog)s {version}'.format(version=VERSION),
        )
    subparsers = parser.add_subparsers(title='Commands', dest='command')
    subparsers.required = True
    subparsers.dest = 'command'

    # List exos
    ls = subparsers.add_parser( # pylint: disable=unused-variable
        'ls',
        help=(
            "List available exercises. Each line of the output can be used as "
            "an argument to other commands."
            ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        )
    ls.add_argument(
        "-v", "--verbose",
        help="Affiche davantage de détails.",
        action="store_true",
        )

    # Generate
    generate_parser = subparsers.add_parser(
        'generate',
        help='Generate some exercises.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        )
    generate_parser.add_argument(
        "exercise",
        metavar='EXERCISE[:SEED[,SEED]]',
        nargs='+', type=exercise_argument, default=None,
        help='Exercises to generate.'
        )
    generate_parser.add_argument(
        '-p', '--pipe',
        nargs=1,
        type=str,
        action='append',
        help=(
            "Commands to run on the LaTeX file before compiling. String '{}' "
            "is replaced by the file name; if not, it is appended at the end "
            "of the string."
            )
        )
    generate_parser.add_argument(
        '-o', '--output',
        type=str,
        default='exercice.pdf',
        help=(
            "Output filename. Default is 'exercice.pdf'."
            ),
        )

    # Test
    test = subparsers.add_parser(
        'test',
        help='Test exercices',
        )
    test.add_argument('args', nargs=argparse.REMAINDER)

    # Dummy
    dummy = subparsers.add_parser(
        'dummy',
        help='Generate a dummy LaTeX file.',
        )
    dummy.add_argument('args', nargs=argparse.REMAINDER)

    return parser

def do_test(options):
    """Action for command line 'test'."""
    from pyromaths.cli.test import __main__
    sys.exit(__main__.main(options.args))

def do_dummy(options):
    """Action for command line 'dummy'."""
    from .cli import dummy
    dummy.main()

def do_generate(options):
    """Action for command line 'generate'."""

    if options.pipe is None:
        options.pipe = []
    else:
        options.pipe = [item[0] for item in options.pipe]

    bag = ExerciseBag()
    exercise_list = []

    for exercise, seeds in options.exercise:
        if not seeds:
            seeds = [random.randint(0, sys.maxsize)]
        for seed in seeds:
            exercise_list.append(bag[exercise](seed))

        exercise_list,
    parametres = {
        'enonce': True,
        'corrige': True,
        'exercices': exercise_list,
        }
    with Fiche(parametres) as fiche:
        fiche.write_tex()
        for command in options.pipe:
            formatted = command.format(fiche.texname)
            if formatted == command:
                formatted = '{} {}'.format(command, fiche.texname)
            subprocess.run(
                    formatted,
                    shell=True,
                    cwd=fiche.workingdir,
                    )
        fiche.write_pdf()
        shutil.copy(fiche.pdfname, options.output)

def do_ls(options): # pylint: disable=unused-argument
    """Perform the `ls` command."""
    bag = ExerciseBag()
    for name in sorted(bag, key=str.lower):
        if options.verbose:
            print(u"{}: {}".format(name, bag[name].description())) # pylint: disable=superfluous-parens
        else:
            print(name) # pylint: disable=superfluous-parens

COMMANDS = {
    "generate": do_generate,
    "ls": do_ls,
    "test": do_test,
    "dummy": do_dummy,
    }

def main():
    """Main function"""
    options = argument_parser().parse_args(sys.argv[1:])

    try:
        COMMANDS[options.command](options)
    except PyromathsException as error:
        logging.error(error)
        sys.exit(1)

if __name__ == "__main__":
    main()

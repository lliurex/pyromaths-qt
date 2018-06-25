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

"""Tests sur les exercices"""

import unittest

from pyromaths.ex import NIVEAUX, ExerciseBag

class TestExercices(unittest.TestCase):

    def test_levels(self):
        allowed_levels = set(NIVEAUX)
        for exo in ExerciseBag().values():
            if not set.intersection(allowed_levels, exo.tags):
                raise AssertionError("L'exercice '{}' doit avoir au moins un tag qui correspond à un niveau.".format(exo.name()))

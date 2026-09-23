"""Regenerate every Ink & Ember sprite and world layer as SVG.

    python3 build.py      -> ../sprites/*.svg, ../world/*.svg
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.chdir(HERE)
os.makedirs("sprites", exist_ok=True)
os.makedirs("world", exist_ok=True)

import runpy
for mod in ("fox", "knight", "dragon", "world"):
    runpy.run_path(os.path.join(HERE, f"{mod}.py"), run_name="__main__")

from sheets import export_props, rig_svg
export_props()
open("sprites/fox-rig.svg", "w").write(rig_svg())

import shutil
for sub in ("sprites", "world"):
    dst = os.path.join(HERE, "..", sub)
    os.makedirs(dst, exist_ok=True)
    for f in os.listdir(sub):
        shutil.copy(os.path.join(sub, f), dst)
    shutil.rmtree(sub)
print("ok")

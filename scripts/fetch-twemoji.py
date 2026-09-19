#!/usr/bin/env python3
"""Fills public/emoji/ with one SVG per emoji the selector can render.

The art is Twemoji, taken from the package Discord publishes so that at-chat shows the
same emoji Discord does. Only the emoji listed in public/emoji.json are copied, plus
their skin tone variations, so re-run this after changing that file.

Twemoji names a file after its code points in hex, joined by '-', and drops the
variation selector U+FE0F unless the sequence also contains a zero width joiner. The
one emoji that doesn't follow that rule gets an extra copy under the name the rule
predicts, so that Twemoji.elm can stay a plain translation of code points to a file
name with no exceptions in it.
"""

import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile

PACKAGE = "@discordapp/twemoji@16.0.1"

SKIN_TONES = ["1F3FB", "1F3FC", "1F3FD", "1F3FE", "1F3FF"]

# The skin tone the variations in public/emoji.json are keyed by. Emoji.elm only reads
# this one and substitutes the modifier for the other tones, so only emoji offering it
# have variations in the app.
BASE_SKIN_TONE = "1F3FB"

ZERO_WIDTH_JOINER = 0x200D
VARIATION_SELECTOR = 0xFE0F

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EMOJI_JSON = os.path.join(REPO_ROOT, "public", "emoji.json")
OUTPUT_DIR = os.path.join(REPO_ROOT, "public", "emoji")


def code_points_to_string(unified):
    return "".join(chr(int(code_point, 16)) for code_point in unified.split("-"))


def file_name(emoji):
    code_points = [ord(character) for character in emoji]

    if ZERO_WIDTH_JOINER not in code_points:
        code_points = [
            code_point for code_point in code_points if code_point != VARIATION_SELECTOR
        ]

    return "-".join("%x" % code_point for code_point in code_points) + ".svg"


def renderable_emoji():
    with open(EMOJI_JSON) as handle:
        emoji_data = json.load(handle)

    emoji = set()

    for entry in emoji_data:
        emoji.add(code_points_to_string(entry["unified"]))

        variations = entry.get("skin_variations") or {}

        if BASE_SKIN_TONE in variations:
            base = code_points_to_string(variations[BASE_SKIN_TONE]["unified"])

            for skin_tone in SKIN_TONES:
                emoji.add(
                    base.replace(
                        code_points_to_string(BASE_SKIN_TONE),
                        code_points_to_string(skin_tone),
                    )
                )

    return emoji


def download_twemoji(directory):
    subprocess.run(
        ["npm", "pack", PACKAGE, "--silent"],
        cwd=directory,
        check=True,
        stdout=subprocess.DEVNULL,
    )

    tarball = next(
        os.path.join(directory, name)
        for name in os.listdir(directory)
        if name.endswith(".tgz")
    )

    with tarfile.open(tarball) as archive:
        archive.extractall(directory)

    return os.path.join(directory, "package", "dist", "svg")


def main():
    emoji = renderable_emoji()

    with tempfile.TemporaryDirectory() as directory:
        source_dir = download_twemoji(directory)

        if os.path.isdir(OUTPUT_DIR):
            shutil.rmtree(OUTPUT_DIR)

        os.makedirs(OUTPUT_DIR)

        missing = []
        total_bytes = 0

        for character in sorted(emoji):
            name = file_name(character)
            source = os.path.join(source_dir, name)

            if os.path.isfile(source):
                shutil.copyfile(source, os.path.join(OUTPUT_DIR, name))
                total_bytes += os.path.getsize(source)
            else:
                missing.append((character, name))

        for character, name in missing:
            fallback = file_name(
                "".join(c for c in character if ord(c) != VARIATION_SELECTOR)
            )
            source = os.path.join(source_dir, fallback)

            if os.path.isfile(source):
                shutil.copyfile(source, os.path.join(OUTPUT_DIR, name))
                total_bytes += os.path.getsize(source)
                print("aliased %s to %s" % (name, fallback))
            else:
                print("no art for %s (%s)" % (character, name), file=sys.stderr)

    print(
        "wrote %d files to public/emoji (%.2f MB)"
        % (len(os.listdir(OUTPUT_DIR)), total_bytes / 1048576)
    )


if __name__ == "__main__":
    main()

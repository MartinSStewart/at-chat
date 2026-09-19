#!/usr/bin/env python3
"""Fills public/emoji/ with the artwork the emoji selector draws.

The art is Twemoji, taken from the package Discord publishes so that at-chat shows the
same emoji Discord does. Only the emoji listed in public/compact-emoji.json are copied,
that being the file the client asks for, plus their skin tone variations. Re-run this
after changing that file.

Two things are written:

  public/emoji/<name>.svg           one file per emoji
  public/emoji/sprites/<name>.svg   one file per category, and one per skin tone

The selector draws a category's grid out of the sprite, because asking for a file per
emoji costs a request each and there are around a hundred and fifty on screen at once.
The single files are still what the recently used row, the category tabs and the hover
preview draw, since those are a handful of emoji from anywhere.

Twemoji names a file after its code points in hex, joined by '-', and drops the
variation selector U+FE0F unless the sequence also contains a zero width joiner. The
one emoji that doesn't follow that rule gets an extra copy under the name the rule
predicts, so that Twemoji.elm can stay a plain translation of code points to a file
name with no exceptions in it.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

PACKAGE = "@discordapp/twemoji@16.0.1"

SKIN_TONES = ["1F3FB", "1F3FC", "1F3FD", "1F3FE", "1F3FF"]

# The skin tone the variations in public/compact-emoji.json are keyed by. Emoji.elm only
# reads this one and substitutes the modifier for the other tones, so only emoji offering
# it have variations in the app.
BASE_SKIN_TONE = "1F3FB"

ZERO_WIDTH_JOINER = 0x200D
VARIATION_SELECTOR = 0xFE0F

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EMOJI_JSON = os.path.join(REPO_ROOT, "public", "compact-emoji.json")
OUTPUT_DIR = os.path.join(REPO_ROOT, "public", "emoji")
SPRITE_DIR = os.path.join(OUTPUT_DIR, "sprites")

SVG_PATTERN = re.compile(r"<svg[^>]*viewBox=\"([^\"]+)\"[^>]*>(.*)</svg>\s*$", re.DOTALL)


def code_points_to_string(unified):
    return "".join(chr(int(code_point, 16)) for code_point in unified.split("-"))


def file_name(emoji):
    code_points = [ord(character) for character in emoji]

    if ZERO_WIDTH_JOINER not in code_points:
        code_points = [
            code_point for code_point in code_points if code_point != VARIATION_SELECTOR
        ]

    return "-".join("%x" % code_point for code_point in code_points)


def category_sprite_name(category):
    """Must match Emoji.categorySpriteName."""
    return re.sub(r"[^a-z0-9]+", "-", category.lower()).strip("-")


def toned(emoji_entry, skin_tone):
    """The variation Emoji.emojiWithSkinTone would draw, or None when there isn't one."""
    variations = emoji_entry.get("skin_variations") or {}

    if BASE_SKIN_TONE not in variations:
        return None

    return code_points_to_string(variations[BASE_SKIN_TONE]["unified"]).replace(
        code_points_to_string(BASE_SKIN_TONE), code_points_to_string(skin_tone)
    )


def read_emoji_data():
    with open(EMOJI_JSON) as handle:
        return json.load(handle)


def renderable_emoji(emoji_data):
    emoji = set()

    for entry in emoji_data:
        emoji.add(code_points_to_string(entry["unified"]))

        for skin_tone in SKIN_TONES:
            variation = toned(entry, skin_tone)

            if variation is not None:
                emoji.add(variation)

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


def copy_art(source_dir, emoji):
    """Copies one file per emoji and says how many bytes that came to."""
    missing = []
    total_bytes = 0

    for character in sorted(emoji):
        name = file_name(character)
        source = os.path.join(source_dir, name + ".svg")

        if os.path.isfile(source):
            shutil.copyfile(source, os.path.join(OUTPUT_DIR, name + ".svg"))
            total_bytes += os.path.getsize(source)
        else:
            missing.append((character, name))

    for character, name in missing:
        without_selector = file_name(
            "".join(c for c in character if ord(c) != VARIATION_SELECTOR)
        )
        source = os.path.join(source_dir, without_selector + ".svg")

        if os.path.isfile(source):
            shutil.copyfile(source, os.path.join(OUTPUT_DIR, name + ".svg"))
            total_bytes += os.path.getsize(source)
            print("aliased %s.svg to %s.svg" % (name, without_selector))
        else:
            print("no art for %s (%s)" % (character, name), file=sys.stderr)

    return total_bytes


def symbol(name):
    """One emoji's art as a <symbol>, read back out of what copy_art wrote."""
    with open(os.path.join(OUTPUT_DIR, name + ".svg")) as handle:
        match = SVG_PATTERN.match(handle.read())

    if match is None:
        raise Exception(name + ".svg isn't shaped like the other Twemoji files")

    return '<symbol id="e%s" viewBox="%s">%s</symbol>' % (
        name,
        match.group(1),
        match.group(2),
    )


def write_sprite(sprite_name, emoji):
    symbols = "".join(symbol(file_name(character)) for character in emoji)
    path = os.path.join(SPRITE_DIR, sprite_name + ".svg")

    with open(path, "w") as handle:
        handle.write('<svg xmlns="http://www.w3.org/2000/svg">' + symbols + "</svg>")

    return os.path.getsize(path)


def write_sprites(emoji_data):
    categories = {}

    for entry in emoji_data:
        categories.setdefault(entry["category"], []).append(
            code_points_to_string(entry["unified"])
        )

    total_bytes = 0

    for category, emoji in categories.items():
        total_bytes += write_sprite(category_sprite_name(category), emoji)

    # One sprite per skin tone rather than a toned copy of each category, because someone
    # picks a single tone and then every category they open needs it.
    for index, skin_tone in enumerate(SKIN_TONES):
        variations = [
            variation
            for variation in (toned(entry, skin_tone) for entry in emoji_data)
            if variation is not None
        ]
        total_bytes += write_sprite("tone-%d" % (index + 1), variations)

    return len(categories) + len(SKIN_TONES), total_bytes


def main():
    emoji_data = read_emoji_data()

    with tempfile.TemporaryDirectory() as directory:
        source_dir = download_twemoji(directory)

        if os.path.isdir(OUTPUT_DIR):
            shutil.rmtree(OUTPUT_DIR)

        os.makedirs(SPRITE_DIR)

        art_bytes = copy_art(source_dir, renderable_emoji(emoji_data))
        sprite_count, sprite_bytes = write_sprites(emoji_data)

    print(
        "wrote %d files to public/emoji (%.2f MB) and %d sprites (%.2f MB)"
        % (
            len(os.listdir(OUTPUT_DIR)) - 1,
            art_bytes / 1048576,
            sprite_count,
            sprite_bytes / 1048576,
        )
    )


if __name__ == "__main__":
    main()

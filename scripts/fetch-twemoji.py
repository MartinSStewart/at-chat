#!/usr/bin/env python3
"""Fills public/emoji/sprites/ with the artwork the emoji selector draws.

The art is Twemoji, taken from the package Discord publishes so that at-chat shows the
same emoji Discord does. Only the emoji listed in public/compact-emoji.json are copied,
that being the file the client asks for, plus their skin tone variations. Re-run this
after changing that file.

Everything ships as sprites, one <symbol> per emoji:

  public/emoji/sprites/<category>.svg   the untoned art, a file per category
  public/emoji/sprites/tone-<n>.svg     the skin tone variations, a file per tone
  public/emoji/sprites/tabs.svg         the emoji the strip of category tabs is drawn with

Asking for a file per emoji costs a request each and there are around a hundred and fifty
on screen at once, so nothing is written one emoji at a time. The tabs get a sprite of
their own because each is an emoji from the category it stands for, and reading them out
of the category sprites would pull all of those in the moment the selector opens.

Twemoji names its art after the emoji's code points in hex, joined by '-', and drops the
variation selector U+FE0F unless the sequence also contains a zero width joiner. The one
emoji that doesn't follow that rule is looked up under the name it really has, so that
Twemoji.elm can stay a plain translation of code points to a name with no exceptions
in it.
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

# The emoji Emoji.categoryToEmojiString draws the tab strip with, including every skin tone
# of the one tab that follows the chosen tone.
TAB_EMOJI = [
    "\U0001F389",
    "\U0001F41F",
    "\U0001F6A9",
    "\U0001F966",
    "\U0001F52C",
    "\U0001F44D",
    "\U0001F44D\U0001F3FB",
    "\U0001F44D\U0001F3FC",
    "\U0001F44D\U0001F3FD",
    "\U0001F44D\U0001F3FE",
    "\U0001F44D\U0001F3FF",
    "\U0001F642",
    "\u2B07\uFE0F",
    "\U0001F686",
]

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


def art_path(source_dir, character):
    """Where Twemoji keeps one emoji's art, or None when it doesn't have any."""
    path = os.path.join(source_dir, file_name(character) + ".svg")

    if os.path.isfile(path):
        return path

    # 👁️‍🗨️ is the one emoji Twemoji itself names against the rule file_name follows.
    without_selector = file_name(
        "".join(c for c in character if ord(c) != VARIATION_SELECTOR)
    )
    path = os.path.join(source_dir, without_selector + ".svg")

    return path if os.path.isfile(path) else None


def symbol(source_dir, character):
    """One emoji's art as a <symbol>, named after the emoji rather than the file."""
    path = art_path(source_dir, character)

    if path is None:
        print("no art for %s (%s)" % (character, file_name(character)), file=sys.stderr)
        return ""

    with open(path) as handle:
        match = SVG_PATTERN.match(handle.read())

    if match is None:
        raise Exception(path + " isn't shaped like the other Twemoji files")

    return '<symbol id="e%s" viewBox="%s">%s</symbol>' % (
        file_name(character),
        match.group(1),
        match.group(2),
    )


def write_sprite(source_dir, sprite_name, emoji):
    symbols = "".join(symbol(source_dir, character) for character in emoji)
    path = os.path.join(SPRITE_DIR, sprite_name + ".svg")

    with open(path, "w") as handle:
        handle.write('<svg xmlns="http://www.w3.org/2000/svg">' + symbols + "</svg>")

    return os.path.getsize(path)


def write_sprites(source_dir, emoji_data):
    categories = {}

    for entry in emoji_data:
        categories.setdefault(entry["category"], []).append(
            code_points_to_string(entry["unified"])
        )

    total_bytes = 0

    for category, emoji in categories.items():
        total_bytes += write_sprite(source_dir, category_sprite_name(category), emoji)

    # One sprite per skin tone rather than a toned copy of each category, because someone
    # picks a single tone and then every category they open needs it.
    for index, skin_tone in enumerate(SKIN_TONES):
        variations = [
            variation
            for variation in (toned(entry, skin_tone) for entry in emoji_data)
            if variation is not None
        ]
        total_bytes += write_sprite(source_dir, "tone-%d" % (index + 1), variations)

    total_bytes += write_sprite(source_dir, "tabs", TAB_EMOJI)

    return len(categories) + len(SKIN_TONES) + 1, total_bytes


def main():
    emoji_data = read_emoji_data()

    with tempfile.TemporaryDirectory() as directory:
        source_dir = download_twemoji(directory)

        if os.path.isdir(OUTPUT_DIR):
            shutil.rmtree(OUTPUT_DIR)

        os.makedirs(SPRITE_DIR)

        sprite_count, sprite_bytes = write_sprites(source_dir, emoji_data)

    print(
        "wrote %d sprites to public/emoji/sprites (%.2f MB)"
        % (sprite_count, sprite_bytes / 1048576)
    )


if __name__ == "__main__":
    main()

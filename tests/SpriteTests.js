// Checks that every emoji the selector can draw has a symbol in the sprite the selector
// would look for it in. Nothing type checks the sprite names in Emoji.elm against the
// files scripts/fetch-twemoji.py writes, and a name that drifts doesn't fail anywhere:
// the <use> just finds nothing and that part of the selector comes up blank.
//
// Run with: node tests/SpriteTests.js

const fs = require("fs");
const path = require("path");

const repoRoot = path.join(__dirname, "..");

const spriteDir = path.join(repoRoot, "public", "emoji");

const skinTones = ["1F3FB", "1F3FC", "1F3FD", "1F3FE", "1F3FF"];

// The one Emoji.elm reads; the others are derived from it by swapping the modifier.
const baseSkinTone = "1F3FB";

function readRepoFile(relativePath) {
    return fs.readFileSync(path.join(repoRoot, relativePath), "utf8");
}

// Pulls the string each branch of an Elm case expression returns, keyed by the
// constructor it matches, so the test reads the names out of the source rather than
// repeating them.
function caseBranches(source, functionName) {
    const branches = new Map();
    const body = functionBody(source, functionName);

    for (const match of body.matchAll(/^        (\w+) ->\n\s+"([^"]+)"$/gm)) {
        branches.set(match[1], match[2]);
    }

    return branches;
}

function functionBody(source, functionName) {
    const start = source.indexOf("\n" + functionName + " ");

    if (start < 0) {
        throw new Error("Couldn't find " + functionName + " in Emoji.elm");
    }

    return source.slice(start, source.indexOf("\n\n\n", start));
}

function codePointsToString(unified) {
    return String.fromCodePoint(
        ...unified.split("-").map((codePoint) => parseInt(codePoint, 16)));
}

// The same rule as Twemoji.fileName.
function symbolId(emoji) {
    let codePoints = [...emoji].map((character) => character.codePointAt(0));

    if (!codePoints.includes(0x200d)) {
        codePoints = codePoints.filter((codePoint) => codePoint !== 0xfe0f);
    }

    return "e" + codePoints.map((codePoint) => codePoint.toString(16)).join("-");
}

function symbolsIn(spriteName) {
    const file = path.join(spriteDir, spriteName + ".svg");

    if (!fs.existsSync(file)) {
        throw new Error(
            spriteName + ".svg isn't in public/emoji, so Emoji.elm names a sprite"
                + " that scripts/fetch-twemoji.py doesn't write");
    }

    return new Set(
        [...fs.readFileSync(file, "utf8").matchAll(/<symbol id="([^"]+)"/g)]
            .map((match) => match[1]));
}

async function run() {
    const failures = [];

    function check(name, body) {
        try {
            body();
            console.log("  passed: " + name);
        } catch (error) {
            failures.push(name + ": " + error.message);
            console.log("  FAILED: " + name + ": " + error.message);
        }
    }

    const emojiSource = readRepoFile("src/Emoji.elm");
    const categoryNames = caseBranches(emojiSource, "categorySpriteName");
    const toneNames = caseBranches(emojiSource, "skinToneSpriteName");
    const categoryTitles = caseBranches(emojiSource, "emojiCategoryToString");
    const emojiData = JSON.parse(readRepoFile("public/compact-emoji.json"));

    check("Emoji.elm names a sprite for every category the data has", () => {
        const fromData = new Set(emojiData.map((entry) => entry.category));
        const fromElm = new Set(
            [...categoryNames.keys()].map((constructor) => categoryTitles.get(constructor)));

        for (const category of fromData) {
            if (!fromElm.has(category)) {
                throw new Error("No sprite is named for " + category);
            }
        }

        if (categoryNames.size !== fromData.size) {
            throw new Error(
                "Elm names " + categoryNames.size + " sprites for "
                    + fromData.size + " categories");
        }
    });

    check("Every emoji is in its own category's sprite", () => {
        const byCategory = new Map();

        for (const entry of emojiData) {
            if (!byCategory.has(entry.category)) {
                byCategory.set(entry.category, []);
            }

            byCategory.get(entry.category).push(entry);
        }

        for (const [constructor, spriteName] of categoryNames) {
            const symbols = symbolsIn(spriteName);
            const entries = byCategory.get(categoryTitles.get(constructor)) || [];

            for (const entry of entries) {
                const id = symbolId(codePointsToString(entry.unified));

                if (!symbols.has(id)) {
                    throw new Error(spriteName + ".svg has no " + id);
                }
            }
        }
    });

    check("Every skin tone variation is in that tone's sprite", () => {
        for (const [index, tone] of skinTones.entries()) {
            const constructor = "SkinTone" + (index + 1);
            const spriteName = toneNames.get(constructor);

            if (spriteName === undefined) {
                throw new Error("Emoji.elm names no sprite for " + constructor);
            }

            const symbols = symbolsIn(spriteName);

            for (const entry of emojiData) {
                const variations = entry.skin_variations || {};

                if (!(baseSkinTone in variations)) {
                    continue;
                }

                // How Emoji.emojiWithSkinTone builds the other tones out of the one it stores.
                const variation =
                    codePointsToString(variations[baseSkinTone].unified)
                        .replace(codePointsToString(baseSkinTone), codePointsToString(tone));

                if (!symbols.has(symbolId(variation))) {
                    throw new Error(spriteName + ".svg has no " + symbolId(variation));
                }
            }
        }
    });

    // The tab strip draws from a sprite of its own rather than the category sprites, since
    // each tab is an emoji from the category it stands for and reading them out of those
    // would pull all ten in the moment the selector opens.
    check("Every category tab's emoji is in the tabs sprite", () => {
        const body = functionBody(emojiSource, "categoryToEmojiString");
        const symbols = symbolsIn("tabs");

        // The literals in there that aren't plain text, which is the "C", "S" and "+" the
        // three categories without art of their own are labelled with.
        const emoji = [...body.matchAll(/"([^"\x00-\x7f][^"]*)"/g)].map((match) => match[1]);

        if (emoji.length === 0) {
            throw new Error("categoryToEmojiString draws no emoji at all");
        }

        for (const character of emoji) {
            if (!symbols.has(symbolId(character))) {
                throw new Error(
                    "tabs.svg has no " + symbolId(character) + ", the tab for " + character);
            }
        }
    });

    check("Sprites hold nothing beyond what the selector asks for", () => {
        const wanted = new Set();

        for (const entry of emojiData) {
            wanted.add(symbolId(codePointsToString(entry.unified)));

            const variations = entry.skin_variations || {};

            if (baseSkinTone in variations) {
                for (const tone of skinTones) {
                    wanted.add(symbolId(
                        codePointsToString(variations[baseSkinTone].unified)
                            .replace(codePointsToString(baseSkinTone), codePointsToString(tone))));
                }
            }
        }

        for (const file of fs.readdirSync(spriteDir)) {
            for (const id of symbolsIn(file.replace(/\.svg$/, ""))) {
                if (!wanted.has(id)) {
                    throw new Error(file + " carries " + id + ", which nothing draws");
                }
            }
        }
    });

    if (failures.length > 0) {
        console.log("\n" + failures.length + " sprite test(s) failed");
        process.exit(1);
    }

    console.log("\nAll sprite tests passed!");
}

run().catch((error) => { console.error(error); process.exit(1); });

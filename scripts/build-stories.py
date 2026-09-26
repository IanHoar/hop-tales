#!/usr/bin/env python3
"""Build HopTalesPackage/Sources/Content/Resources/stories.json from Design/stories/stories.txt.

The text file is the source of truth; the JSON is generated and committed. The format is described
at the top of the text file. Sentence lengths outside a level's range are reported, not refused,
so an older story can stay as written.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Design/stories/stories.txt"
OUTPUT = ROOT / "HopTalesPackage/Sources/Content/Resources/stories.json"

SENTENCE_WORDS = {1: (3, 5), 2: (5, 7), 3: (6, 8), 4: (7, 9), 5: (8, 10), 6: (9, 12), 7: (10, 14)}
SKIES = {"day", "golden", "dusk", "night"}
WEATHERS = {"clear", "clouds", "storm", "rain"}

HOMOPHONES = {
    "be": ["bee"], "bee": ["be"], "blue": ["blew"], "blew": ["blue"], "by": ["buy", "bye"],
    "flowers": ["flours"], "flower": ["flour"], "for": ["four"], "hare": ["hair"],
    "hear": ["here"], "here": ["hear"], "hole": ["whole"], "whole": ["hole"], "in": ["inn"],
    "knew": ["new"], "new": ["knew"], "know": ["no"], "no": ["know"], "meet": ["meat"],
    "night": ["knight"], "one": ["won"], "pail": ["pale"], "rain": ["reign", "rein"],
    "red": ["read"], "right": ["write"], "road": ["rode"], "sea": ["see"], "see": ["sea"],
    "sun": ["son"], "tail": ["tale"], "their": ["there"], "there": ["their"],
    "to": ["two", "too"], "too": ["two", "to"], "waits": ["weights"], "way": ["weigh"],
    "wood": ["would"], "tide": ["tied"], "rows": ["rose"], "bows": ["boughs"],
    "sail": ["sale"], "flew": ["flu"], "stares": ["stairs"], "pair": ["pear"],
    "peace": ["piece"], "piece": ["peace"], "hour": ["our"], "hours": ["ours"],
    "we": ["wee"], "ate": ["eight"], "dear": ["deer"], "cellar": ["seller"],
}


def fail(line_number, message):
    sys.exit(f"{SOURCE.name}:{line_number}: {message}")


def parse_header(line, line_number):
    parts = [part.strip() for part in line[2:].split("|")]
    if len(parts) < 4:
        fail(line_number, "a story header is: == id | Title | level N | sky weather [| flags]")
    story_id, title, level, mood, *flags = parts
    match = re.fullmatch(r"level ([1-7])", level)
    if not match:
        fail(line_number, f"unknown level '{level}'")
    sky, weather = mood.split()
    if sky not in SKIES or weather not in WEATHERS:
        fail(line_number, f"unknown mood '{mood}'")
    unknown = set(flags) - {"stretch", "big"}
    if unknown:
        fail(line_number, f"unknown flags {sorted(unknown)}")
    return {
        "id": story_id,
        "title": title,
        "level": int(match.group(1)),
        "stretch": "stretch" in flags,
        "isBigStory": "big" in flags,
        "mood": {"sky": sky, "weather": weather},
        "sentences": [],
    }


def parse_sentence(line, line_number):
    sentence = {"newWord": None, "words": []}
    tags = re.match(r"\[([a-z ]+)\]\s*", line)
    if tags:
        for tag in tags.group(1).split():
            if tag in SKIES:
                sentence["sky"] = tag
            elif tag in WEATHERS:
                sentence["weather"] = tag
            else:
                fail(line_number, f"unknown mood tag '{tag}'")
        line = line[tags.end():]
    tokens = line.split()
    if not tokens or not re.search(r"[.!?][”’\"]*$", tokens[-1]):
        fail(line_number, "a sentence ends with a full stop, a question mark or an exclamation mark")
    for token in tokens:
        lead = re.match(r"^[“‘\"(]*", token).group(0)
        trail = re.search(r"[,.!?;:”’\")]*$", token).group(0)
        token = token[len(lead):len(token) - len(trail)]
        new = token.startswith("^")
        token = token.lstrip("^")
        big = token.startswith("*") and token.endswith("*")
        text = token.strip("*")
        if not re.fullmatch(r"[A-Za-z]+", text):
            fail(line_number, f"'{token}' isn't a plain word")
        if new:
            sentence["newWord"] = text
        word = {"text": text, "homophones": HOMOPHONES.get(text.lower(), []), "big": big}
        if lead:
            word["leading"] = lead
        if trail:
            word["trailing"] = trail
        sentence["words"].append(word)
    return sentence


def main():
    stories = []
    for line_number, raw in enumerate(SOURCE.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("=="):
            stories.append(parse_header(line, line_number))
            continue
        if not stories:
            fail(line_number, "a sentence before the first story header")
        stories[-1]["sentences"].append(parse_sentence(line, line_number))

    ids = [story["id"] for story in stories]
    duplicates = {story_id for story_id in ids if ids.count(story_id) > 1}
    if duplicates:
        sys.exit(f"duplicate story ids: {sorted(duplicates)}")

    for story in stories:
        low, high = SENTENCE_WORDS[story["level"]]
        for sentence in story["sentences"]:
            count = len(sentence["words"])
            if not low <= count <= high:
                words = " ".join(word["text"] for word in sentence["words"])
                print(f"note: {story['id']} (level {story['level']}): {count} words: {words}")

    OUTPUT.write_text(json.dumps(stories, indent=2) + "\n")
    print(f"wrote {len(stories)} stories to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

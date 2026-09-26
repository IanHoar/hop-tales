#!/usr/bin/env python3
"""Build HopTalesPackage/Sources/Content/Resources/stories.json from Design/stories/stories.txt.

The text file is the source of truth; the JSON is generated and committed. The format is described
at the top of the text file. The build refuses a sentence outside its level's length, or a word a
reader at that level can't decode yet, using the level table in phonics.json.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Design/stories/stories.txt"
OUTPUT = ROOT / "HopTalesPackage/Sources/Content/Resources/stories.json"
PHONICS = ROOT / "HopTalesPackage/Sources/Content/Resources/phonics.json"

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


class Phonics:
    """The same decoder as Content/Phonics.swift, reading the same table."""

    VOWELS = set("aeiou")
    SILENT_E_TAILS = {"", "s", "d", "r", "ly", "ful", "less", "ment", "ness", "st"}
    END_TAILS = {"", "s", "d"}
    CONSONANT_UNITS = {"qu", "dge", "ce", "ge", "ve"}

    def __init__(self, path):
        table = json.loads(path.read_text())
        self.rules = table["rules"]
        self.graphemes, self.ends, self.heart = {}, {}, {}
        for level in table["levels"]:
            for grapheme in level["graphemes"]:
                self.graphemes[grapheme] = level["level"]
            for grapheme in level["endGraphemes"]:
                self.ends[grapheme] = level["level"]
            for word in level["heartWords"]:
                self.heart[word] = level["level"]
        for name in table["names"]:
            self.heart[name.lower()] = 1
        self.by_length = sorted(self.graphemes, key=len, reverse=True)
        self.ends_by_length = sorted(self.ends, key=len, reverse=True)

    def level(self, word):
        word = word.lower()
        found = [level for level in (self.heart.get(word), self.decoded(word)) if level]
        return min(found) if found else None

    def decoded(self, word):
        ending = self.ending(word)
        if ending:
            suffix, bases = ending
            levels = [self.level(base) for base in bases]
            levels = [level for level in levels if level]
            return max(self.rules["endings"], min(levels)) if levels else None
        return self.segmented(word)

    def ending(self, word):
        for suffix in ("ing", "ed"):
            base = word[: -len(suffix)]
            if word.endswith(suffix) and set(base) & self.VOWELS and not base.endswith("e"):
                if base.endswith(("c", "dg", "v")):
                    bases = [base + "e"]
                elif self.split(base + "e") is not None:
                    bases = [base, base + "e"]
                else:
                    bases = [base]
                if len(base) > 2 and base[-1] == base[-2]:
                    bases.append(base[:-1])
                return suffix, bases
        base = word[:-2]
        if word.endswith("es") and base.endswith(("ss", "x", "z", "ch", "sh")):
            return "es", [base]
        return None

    def split(self, word):
        for index in range(len(word) - 2):
            vowel, consonant = word[index], word[index + 1]
            before = word[index - 1] if index else ""
            opens = before not in self.VOWELS or word[index - 2 : index] == "qu"
            if (vowel in self.VOWELS and opens and consonant not in self.VOWELS
                    and consonant not in "rwxy" and word[index + 2] == "e"
                    and word[index + 3 :] in self.SILENT_E_TAILS):
                return index
        return None

    def segmented(self, word):
        split = self.split(word)
        tokens, position = [], 0
        while position < len(word):
            if position == split:
                tokens.append((word[position] + "_e", self.rules["splitDigraphs"], True))
                position += 1
                continue
            if split is not None and position == split + 2:
                position += 1
                continue
            match = None
            for grapheme in self.ends_by_length:
                tail = word[position + len(grapheme) :]
                follows = grapheme != "le" or word[position - 1] not in self.VOWELS
                if position and follows and split is None and word.startswith(grapheme, position) and tail in self.END_TAILS:
                    match = (grapheme, self.ends[grapheme], grapheme == "le")
                    break
            if not match:
                for grapheme in self.by_length:
                    end = position + len(grapheme)
                    covers = split is not None and position <= split + 2 < end
                    if word.startswith(grapheme, position) and not covers:
                        vowel = bool(set(grapheme) & self.VOWELS) and grapheme not in self.CONSONANT_UNITS
                        match = (grapheme, self.graphemes[grapheme], vowel)
                        break
            if not match:
                return None
            grapheme, level, vowel = match
            if grapheme == "y" and position and not tokens[-1][2]:
                match = (grapheme, self.rules["vowelY"], True)
            tokens.append(match)
            position += len(grapheme)
        level = max(token[1] for token in tokens)
        pairs = list(zip(tokens, tokens[1:]))
        if pairs and word.endswith("s") and tokens[-1][0] == "s":
            pairs.pop()
        if any(not a[2] and not b[2] for a, b in pairs):
            level = max(level, self.rules["clusters"])
        if sum(token[2] for token in tokens) > 1:
            level = max(level, self.rules["syllables"])
        return level


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

    phonics = Phonics(PHONICS)
    problems = []
    for story in stories:
        level = story["level"]
        low, high = SENTENCE_WORDS[level]
        for sentence in story["sentences"]:
            words = " ".join(word["text"] for word in sentence["words"])
            count = len(sentence["words"])
            if not low <= count <= high:
                problems.append(f"{story['id']} (level {level}): {count} words: {words}")
            for word in sentence["words"]:
                decodes = phonics.level(word["text"])
                ceiling = min(level + 2, 7) if word["big"] else level
                if decodes is None or decodes > ceiling:
                    at = f"level {decodes}" if decodes else "no level"
                    kind = "big word" if word["big"] else "word"
                    problems.append(f"{story['id']} (level {level}): {kind} '{word['text']}' decodes at {at}")
    if problems:
        sys.exit("\n".join(problems))

    OUTPUT.write_text(json.dumps(stories, indent=2) + "\n")
    print(f"wrote {len(stories)} stories to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

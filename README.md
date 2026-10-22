# pkmn-ricciolino

<p align="center">
  <img src="media/demo.gif" alt="pkmn-ricciolino — gameplay" width="480">
</p>

A from-scratch remake of the first-generation Game Boy Pokémon games, built in Godot.
It is a **Red + Blue fusion**, rebuilt tile by tile so that the whole Pokédex can be
completed in a single playthrough — plus a few liberties of my own.

<p align="center">
  <img src="media/title.png"        alt="Title screen"  width="24%">
  <img src="media/overworld.png"    alt="Overworld"     width="24%">
  <img src="media/battle.png"       alt="Battle"        width="24%">
  <img src="media/trainer-card.png" alt="Trainer card"  width="24%">
</p>

---

## Downloads

| Platform | How to get it |
|---|---|
| **Linux desktop** | [Releases](../../releases) — a single self-contained binary, no installer required |
| **Android** | [Releases](../../releases) — APK, sideload it |
| **iOS / iPadOS** | **On request.** Email **ricciolinotop@gmail.com** to be added to the TestFlight internal testing group. There are no plans to put it on the App Store |

> This repository holds **only the builds**. The source lives in a separate, private
> repository.

---

## What this is

As a kid I never had a Game Link cable, so my Pokédex always stopped a few entries short —
the trade evolutions were simply out of reach. Building a version that one person could
finish alone has been a small dream of mine ever since.

Red and Blue were built to be incomplete: each cartridge was missing creatures the other
one had, and the only way to fill the gap was that cable and a friend with the other
version.

So here it is, rebuilt from nothing. Not a ROM hack and not a patch: a
**remake written from scratch** in Godot — its own engine code, its own maps, its own
battle system — with one decision at the centre of it: **one player, one copy, one complete
Pokédex.** Every species obtainable somewhere, trade evolutions included, without ever
needing a second console.

The look stays faithful on purpose: the Game Boy palettes, the text boxes, the Gen 1 battle
maths down to the critical-hit formula. What changed is what had to change for a single
player to see all of it.

### …and one more thing

There is a **152nd creature**, designed by me, that is not in the original Pokédex.

It cannot be caught normally. The only way in is a **glitch I put there on purpose** — and
you can work out that it exists from the very first minutes of the game, if you are paying
attention to everything. Especially to one particular line of dialogue. 👀

---

## Honest notes before you play

This is a remake made by one person, and some things are deliberately not identical to the
cartridge. None of them affect how the game plays, but you will notice them:

- **Grass tufts don't sway**, and the **sea doesn't ripple** — the world is drawn, not
  animated. Ambient tile animation is simply not implemented.
- **Move animations are simplified.** Every move works, with its real Gen 1 behaviour, but
  the effects on screen are not a frame-by-frame reproduction of the original.
- **Not every sound matches.** Music and effects were rebuilt and re-tuned by ear; some are
  very close, some are an interpretation.
- **A few personal liberties.** Where Gen 1 had a famous bug that would simply read as *my*
  bug to anyone playing today, I fixed it instead of preserving it.

Everything else — the story from Pallet Town to the Hall of Fame, the eight badges, the
Elite Four, the post-game — is there and finished.

---

## Under the hood

| | |
|---|---|
| **Engine** | Godot **4.4.1**, Compatibility renderer (OpenGL) |
| **Language** | GDScript |
| **Resolution** | 150×155 px viewport, 144×144 play area, 16 px tiles, nearest-neighbour |
| **Content** | 220 maps · 152 species · 177 moves · full EN/IT localisation |
| **Input** | Keyboard, touch and USB gamepad — every feature works on all three |
| **Platforms** | Linux desktop, Android, iOS |

Builds are produced **by hand, on my own machines** — no CI, no hosted runners. Each
release is tagged, and the tag carries its own notes.

---

## Reporting something

Found a bug, a wrong name, a wall you can walk through? Open an
[issue](../../issues) and say which version you are on — the game shows it in the top bar
and in **Options → About**, in the form `0.1.2 (5)`.

---

## Credits and legal

Pokémon, Pokémon Red and Pokémon Blue are trademarks of Nintendo, Creatures Inc. and
GAME FREAK Inc. This is a **non-commercial fan project**, built for the pleasure of
building it, and is not affiliated with or endorsed by any of them. No original game data
is distributed here.

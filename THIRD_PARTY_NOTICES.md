# Third-party notices

`LICENSE.md` is the **Unlicense**. This file is not part of it and does not qualify it: it records
what **third-party** material this repository ships, where it came from, and what it obliges — the
things a public-domain dedication cannot reach, because they are not the project's to give away.

*Compiled 2026-09-03 by measurement, not from memory. Each row states how it was checked.*

## Embedded third-party material

### DejaVu fonts — **embedded outlines, not merely referenced**

`example/report.pdf` **embeds the full DejaVu font programs**. Measured with `pdffonts`:

| font | type | embedded | subsetted |
|---|---|---|---|
| `DejaVuSans` | CID TrueType | **yes** | no |
| `DejaVuSans-Bold` | CID TrueType | **yes** | no |
| `DejaVuSansMono` | CID TrueType | **yes** | no |

`emb yes` means the outlines themselves are in the file; `sub no` means the whole font is embedded,
not a subset of used glyphs. This is redistribution of the font program, not a reference to it.

DejaVu is distributed under the **Bitstream Vera Fonts Copyright**. Its grant is conditioned on the
notice being included *"in all copies of one or more of the Font Software typefaces"* — a link is not
inclusion, so the notice is **reproduced in full below** rather than referenced. **Nothing in this
repository modifies or supersedes it, and the Unlicense does not apply to it.**

Transcribed verbatim from `/usr/share/doc/fonts-dejavu-core/copyright` (Debian package
`fonts-dejavu-core`) on 2026-09-03; upstream copy at <https://dejavu-fonts.github.io/License.html>.

```
Copyright (c) 2003 by Bitstream, Inc. All Rights Reserved.
Bitstream Vera is a trademark of Bitstream, Inc.
DejaVu changes are in public domain.
Permission is hereby granted, free of charge, to any person obtaining a copy
of the fonts accompanying this license ("Fonts") and associated
documentation files (the "Font Software"), to reproduce and distribute the
Font Software, including without limitation the rights to use, copy, merge,
publish, distribute, and/or sell copies of the Font Software, and to permit
persons to whom the Font Software is furnished to do so, subject to the
following conditions:

The above copyright and trademark notices and this permission notice shall
be included in all copies of one or more of the Font Software typefaces.

The Font Software may be modified, altered, or added to, and in particular
the designs of glyphs or characters in the Fonts may be modified and
additional glyphs or characters may be added to the Fonts, only if the fonts
are renamed to names not containing either the words "Bitstream" or the word
"Vera".

This License becomes null and void to the extent applicable to Fonts or Font
Software that has been modified and is distributed under the "Bitstream
Vera" names.

The Font Software may be sold as part of a larger software package but no
copy of one or more of the Font Software typefaces may be sold by itself.

THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF COPYRIGHT, PATENT,
TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL BITSTREAM OR THE GNOME
FOUNDATION BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, INCLUDING
ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM OTHER DEALINGS IN THE
FONT SOFTWARE.

Except as contained in this notice, the names of Gnome, the Gnome
Foundation, and Bitstream Inc., shall not be used in advertising or
otherwise to promote the sale, use or other dealings in this Font Software
without prior written authorization from the Gnome Foundation or Bitstream
Inc., respectively. For further information, contact: fonts at gnome dot
org.
```

Two conditions in that text are worth naming explicitly, because they are the only things this
repository asks of a reuser: keep the notice with any copy of the typefaces, and do not sell a copy
of the typefaces **by itself** (selling them as part of a larger package, including this one, is
expressly permitted). Neither constrains any use of the project's own content.

⚠ No `.ttf`/`.otf`/`.woff` files are tracked (`git ls-files` → none); the only embedding is inside the
generated PDF. `report.html` and the two `reports/figures/*.svg` name DejaVu as a CSS/SVG
`font-family` only, which is a reference and not redistribution.

## Cited, not redistributed

Checked by reading the citing sites rather than assuming from a name match:

- **OEIS** — appears as links (e.g. `https://oeis.org/A102241`) and as reader orientation in
  `documentation/CITATIONS.md`. OEIS content is CC BY-SA; **no OEIS term list is reproduced here**,
  so the citation is a pointer, not a derivative.
- **Shaughnessy, Nielsen, and the other scholarly sources** — cited in prose with page loci in
  `documentation/CITATIONS.md`. Their arrays and translations are **not** reproduced; where a value
  is quoted it is quoted as a cited figure.

## Scope of this file

This file covers third-party material only. For the terms on the project's own code, prose and data,
see [LICENSE.md](LICENSE.md) — nothing here adds to or subtracts from it.

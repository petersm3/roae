# Third-party notices

`LICENSE.md` is the **Unlicense**, and the Unlicense is **software-scoped** — its text dedicates
"this software" to the public domain. This repository also ships prose, data tables, generated
artifacts and some third-party material, and this file records what is here and where it came from.

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

DejaVu is distributed under the **Bitstream Vera Fonts Copyright** (with the DejaVu changes released
by their authors); the upstream licence text and its conditions — including its notice requirement
and its restriction on using the reserved font names — are at
<https://dejavu-fonts.github.io/License.html>. **Nothing in this repository modifies or supersedes
it, and the Unlicense does not apply to it.**

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

## 🔴 Not settled here — project-authored non-software content

The Unlicense covers the software. **This repository has no explicit dedication for its
project-authored prose, data tables and generated artifacts**, and choosing one (CC0, CC BY, or an
explicit public-domain dedication) is a licensing decision for the copyright holder, not something a
notices file can assume. Until it is made, the status of that material is simply unstated.

Reader-facing consequence, stated plainly: a third party who wants to reuse the **prose or the data
tables** cannot currently tell from this repository what terms apply to them.

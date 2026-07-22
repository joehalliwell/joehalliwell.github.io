# joehalliwell.github.io

My website, at <https://joehalliwell.com>. Made with [Quarto](https://quarto.org/).

The blog used to live in a separate repo, published under `/blog`. It was merged
here in July 2026 and now sits at the top level; `/blog/*` URLs redirect.

Alongside the Quarto project there is a pile of older static pages (sketches,
talks, `thesis.pdf`, ...) that keep their original URLs. They are carried into
the build verbatim via `resources:` in `_quarto.yml`; `just check` asserts they
survive.

```sh
just preview   # local server with live reload
just check     # render, then assert no URLs have gone missing
just publish   # push the built site to the gh-pages branch
```

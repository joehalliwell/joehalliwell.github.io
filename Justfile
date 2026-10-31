# Lint and reflow posts via the pre-commit hooks; a pass that only reflows exits 1, so run twice
lint:
    pre-commit run --all-files || pre-commit run --all-files

# Render the site
render: lint
    quarto render

# Rebuild the subsetted webfonts in assets/fonts/ (rarely needed; they're committed)
fonts:
    bash _scripts/build-fonts.sh

# Report what the text column actually renders at, in characters
measure page="posts/rust-tools/index.html" width="1440":
    bash _scripts/measure-column.sh {{page}} {{width}}

# The fetch is best-effort so that check still works offline, against the last
# fetched copy of gh-pages.
#
# Rendering from inside a hidden directory (e.g. an agent worktree under
# .claude/) silently drops the .md and .ipynb posts, so check fails there.

# Render, then assert nothing served has gone missing, nothing hidden ships, and no page uses h4+
check: render
    git fetch --quiet origin gh-pages || echo "warning: could not fetch gh-pages; checking against the last fetched copy" >&2
    bash _scripts/check-served.sh
    bash _scripts/check-hidden.sh
    bash _scripts/check-headings.sh

# Test the checks themselves against planted defects
test:
    bash _scripts/test-checks.sh

# --no-render matters: without it quarto renders a second time into its own
# worktree and publishes that, so the build `check` just validated is not the
# build that goes up.
#
# quarto commits to gh-pages, which has no .pre-commit-config.yaml;
# PRE_COMMIT_ALLOW_NO_CONFIG stops the pre-commit hook failing that commit.

# Publish the checked build to GitHub Pages
publish: check
    PRE_COMMIT_ALLOW_NO_CONFIG=1 quarto publish --no-prompt --no-browser --no-render gh-pages

# Start a local preview server with live reload
preview:
    quarto preview

# Agent worktrees under .claude/ are left alone: they are other checkouts, not
# debris. .vscode/ is ignored, not debris, and also left alone.

# Remove build output, caches and other render debris
clean:
    rm --recursive --force build .quarto _freeze .jupyter_cache .rumdl_cache _quarto_internal_scss_error.scss
    find . \( -path ./.git -o -path ./.claude \) -prune -o -name '*.quarto_ipynb' -type f -print -delete

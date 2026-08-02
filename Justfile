# Render the site
render:
    quarto render

# Rebuild the subsetted webfonts in assets/fonts/ (rarely needed; they're committed)
fonts:
    bash _scripts/build-fonts.sh

# Report what the text column actually renders at, in characters
measure page="posts/rust-tools/index.html" width="1440":
    bash _scripts/measure-column.sh {{page}} {{width}}

# Render, then assert that no previously-served URL has gone missing
check: render
    bash _scripts/check-urls.sh

# --no-render matters: without it quarto renders a second time into its own
# worktree and publishes that, so the build `check` just validated is not the
# build that goes up.

# Publish the checked build to GitHub Pages
publish: check
    quarto publish --no-prompt --no-browser --no-render gh-pages

# Start a local preview server with live reload
preview:
    quarto preview

# Remove build output and caches
clean:
    rm -rf build .quarto _freeze

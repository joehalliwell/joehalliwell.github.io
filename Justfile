# Render the site
render:
    quarto render

# Render, then assert that no previously-served URL has gone missing
check: render
    bash _scripts/check-urls.sh

# Publish the site to GitHub Pages
publish: check
    quarto publish --no-prompt --no-browser gh-pages

# Start a local preview server with live reload
preview:
    quarto preview

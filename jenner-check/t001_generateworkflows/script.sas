/* ------------------------------------------------------------------ *
 * Bundle: t001_generateworkflows
 * Source: sasdogs/macro/_inner.sas  (the _generateWorkflows macro)
 *
 * Exercises the SASDoGs _generateWorkflows macro, which writes a
 * GitHub Actions workflow (deploy.yml) that builds the package docs
 * (Jupyter Book, MyST or Sphinx) and deploys them to GitHub Pages.
 * The macro body below is the package code, unchanged. Only a caller
 * and a read-back step are added so the run is self contained: the
 * workflow file is written into the WORK directory and echoed to log.
 * ------------------------------------------------------------------ */

%macro _generateWorkflows(repoLocation   =
                        , branch         = main
                        , relDocLocation = docs
                        , wfLocation     =
);
  
  %let wfref = _%sysfunc(datetime(), hex6.)w ;
  %if %superq(wfLocation) eq %then
  /* Output to .github/workflows */
    %do ;
      libname &wfref. "&repoLocation./.github";
      libname &wfref. clear;
      libname &wfref. "&repoLocation./.github/workflows";
      libname &wfref. clear;
      filename &wfref. "&repoLocation./.github/workflows/deploy.yml";
    %end ;
  %else
    filename &wfref. "&wfLocation./deploy.yml"; ;


  %put NOTE: Ensure your GitHub Pages settings for this repository are set to deploy with **GitHub Actions**.;

  data _null_ ;
    file &wfref. ;
    
    put "name: Docs (Jupyter Book/Sphinx) GitHub Pages Deploy" ;
    put "on:" ;
    put "  release:" ;
    put "    types: [published]" ;
    put "  workflow_dispatch:" ;
    put "    inputs:" ;
    put "      builder:" ;
    put "        description: 'Docs builder to use (auto, jupyterbook, sphinx)'" ;
    put "        required: false" ;
    put "        default: 'auto'" ;
    put "env:" ;
    put "  BASE_URL: /${{ github.event.repository.name }}" ;
    put " " ;
    put "permissions:" ;
    put "  contents: read" ;
    put "  pages: write" ;
    put "  id-token: write" ;
    put "concurrency:" ;
    put "  group: 'pages'" ;
    put "  cancel-in-progress: false" ;
    put "jobs:" ;
    put "  deploy:" ;
    put "    environment:" ;
    put "      name: github-pages" ;
    put "      url: ${{ steps.deployment.outputs.page_url }}" ;
    put "    runs-on: ubuntu-latest" ;
    put "    steps:" ;
    put "      - uses: actions/checkout@v4" ;
    put "      - name: Setup Pages" ;
    put "        uses: actions/configure-pages@v3" ;
    put "      - name: Setup Python" ;
    put "        uses: actions/setup-python@v5" ;
    put "        with:" ;
    put "          python-version: '3.11'" ;
    put "      - uses: actions/setup-node@v4" ;
    put "        with:" ;
    put "          node-version: '18.x'" ;
    put "      - name: Detect docs builder" ;
    put "        id: detect" ;
    put "        run: |" ;
    put "          set -euo pipefail" ;
    put '          builder_input="${{ inputs.builder ||' "'auto'" '}}"' ;
    put '          if [[ "$builder_input" != "auto" ]]; then' ;
    put '            echo "builder=$builder_input" >> "$GITHUB_OUTPUT"' ;
    put "            exit 0" ;
    put "          fi" ;
    put " " ;
    put '          if [[ -f "docs/myst.yml" ]]; then' ;
    put '            echo "builder=jupyterbook" >> "$GITHUB_OUTPUT"' ;
    put "            exit 0" ;
    put "          fi" ;
    put " " ;
    put "          if [[ -f 'docs/conf.py' ]]; then" ;
    put '            echo "builder=sphinx" >> "$GITHUB_OUTPUT"' ;
    put "            exit 0" ;
    put "          fi" ;
    put " " ;
    put '          echo "No docs/myst.yml or docs/conf.py found. Please add one or select a builder." >&2' ;
    put "          exit 1" ;
    put "      - name: Install Jupyter Book (via myst)" ;
    put "        if: steps.detect.outputs.builder == 'jupyterbook'" ;
    put "        run: npm install -g jupyter-book" ;
    put "      - name: Install Sphinx" ;
    put "        if: steps.detect.outputs.builder == 'sphinx' " ;
    put "        run: python -m pip install --upgrade pip sphinx myst-nb sphinx-book-theme sphinx-rtd-theme" ;
    put "      - name: Build HTML Assets (Jupyter Book)" ;
    put "        if: steps.detect.outputs.builder == 'jupyterbook'" ;
    put "        run: jupyter-book build --html" ;
    put "        working-directory: &relDocLocation." ;
    put "      - name: Build HTML Assets (Sphinx)" ;
    put "        if: steps.detect.outputs.builder == 'sphinx'" ;
    put "        run: sphinx-build -b html &relDocLocation. &relDocLocation./_build/html" ;
    put "      - name: Upload artifact" ;
    put "        uses: actions/upload-pages-artifact@v3" ;
    put "        with:" ;
    put "          path: './&relDocLocation./_build/html'" ;
    put "      - name: Deploy to GitHub Pages" ;
    put "        id: deployment" ;
    put "        uses: actions/deploy-pages@v4" ;
  run ;

  filename &wfref. clear;

%mend _generateWorkflows;

/* --- caller: generate deploy.yml into the WORK directory --- */
%let workdir = %sysfunc(pathname(work));
%let wfout   = &workdir./workflows;
libname _w "&wfout.";
libname _w clear;

%_generateWorkflows(
  repoLocation   = &workdir./myrepo,
  branch         = main,
  relDocLocation = docs,
  wfLocation     = &wfout.
);

/* --- echo the generated workflow to the log --- */
title "deploy.yml generated by the _generateWorkflows macro";
data _null_;
  infile "&wfout./deploy.yml";
  input;
  putlog _infile_;
run;
title;

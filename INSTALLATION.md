# Installing fegraph

## Requirements

`fegraph` uses official Stata/Mata and targets Stata 16 or newer.
Execution has been tested on macOS Stata/MP 19; Stata 16–18 and Windows/Linux
have not been qualified. No compiler, native plugin or third-party graph
package is required.

HTML export also runs entirely from Stata. A modern browser plays the exported
file offline; users do not need Python, Node.js, D3 or a web server.

## Install from GitHub

```stata
net install fegraph, replace ///
    from("https://raw.githubusercontent.com/johannes-schmieder/fegraph/main/")
```

This installs the current package from `main`, including the Ado/Mata files,
help, runnable examples, optional report helper and two HTML viewer resources.
GitHub authentication and a Git checkout are not needed for the public package.
No SSC release is currently provided.

Verify the installation:

```stata
fegraph, version
fegraph, selftest
help fegraph
fegraph_run ladder using fegraph.sthlp
```

The selftest and example preserve your data. Open `help fegraph` for 18
self-contained examples with clickable run links.

## Updating an existing installation

Restart Stata, then rerun the same `net install ..., replace` command.
Restarting clears cached Ado/Mata definitions from an older version.
Check the active copy if you have used multiple development installations:

```stata
which fegraph
adopath
fegraph, version
```

An earlier development checkout added with `adopath ++` can shadow your newly
installed copy. Remove that specific temporary path or start a fresh Stata
session; do not delete unrelated Ado files.

Since version 0.2, positional variables supply scores. Put old positional firm
IDs in `firm()`, and prepared-flow endpoints in `origin()`/`destination()`.
The canonical network name is `type(firmgraph)`; `type(firm)` remains an alias.

## Local installation

Clone or download the repository, then point Stata at the directory containing
`fegraph.pkg` and `stata.toc`:

```stata
net install fegraph, replace from("/absolute/path/to/fegraph")
```

For a temporary development session, run from the repository root:

```stata
adopath ++ stata
do examples/command_gallery.do
```

Generated figures, logs and datasets belong in the ignored `build/` directory.
The checked-in README images are synthetic documentation illustrations.

## Optional simulation reports

The graph command needs none of these companions. The report examples need
Stata 19 and installed, compatible versions of:

- [fesim](https://github.com/johannes-schmieder/fesim)
- [fereg](https://github.com/johannes-schmieder/fereg)
- [ferank](https://github.com/johannes-schmieder/ferank)
- [latexlog](https://github.com/johannes-schmieder/latexlog)
- [texpdf](https://github.com/johannes-schmieder/texpdf)

Follow each package's installation instructions, then run:

```stata
fegraph_run report_all using fegraph.sthlp
```

The examples do not install companions or download data automatically.
See the [example index](examples/README.md) for separate model reports.

## Troubleshooting

**The HTML has a header but no graph in a file preview.** Save/download the file
and open it directly in a browser such as Chrome. Some app previews restrict
embedded JavaScript. No external resources need to load.

**A viewer resource cannot be found.** Reinstall the complete package.
Copying only `fegraph.ado` omits its helpers, Mata source and HTML templates.

**A report says a companion is missing.** Install the optional dependencies
above, or use the native graph and animation examples, which require only fegraph.

**Installation cannot reach GitHub.** Check your connection and Stata's HTTPS
access, or download the repository and use the local installation route.

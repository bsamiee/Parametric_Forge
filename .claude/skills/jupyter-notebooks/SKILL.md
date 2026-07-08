---
name: jupyter-notebooks
description: Execute, parameterize, convert, validate, and edit Jupyter notebooks, plus drive a live interactive kernel. Use when working with .ipynb files, running or parameterizing a notebook (papermill), converting between .py and .ipynb (jupytext), exporting notebooks to HTML or script (nbconvert), validating notebook JSON, or exploring data in a persistent JupyterLab kernel with state held across cells. Covers a deterministic, server-free batch path and an interactive live-kernel path, chosen by whether cross-cell kernel state must persist. Not for plain .py script execution, which is ordinary Python.
---

# Jupyter notebooks

Two execution paths, chosen by need. Batch is the default: deterministic, re-runnable, server-free, pure-Python on the scientific interpreter. Interactive is for live exploration in a persistent kernel through the `jupyter` MCP.

## Path selection

- Batch — execute, parameterize, convert, or validate a notebook deterministically with no server. The default for pipelines, re-runnable runs, and verification. Pure `uv run` on the scientific interpreter.
- Interactive — explore in a live kernel with state held across cells. The `jupyter` MCP over a running JupyterLab server. Use only when live kernel state matters; otherwise batch.

## Batch — no server

Every tool is pure-Python and runs through `uv run` on the scientific interpreter; the spawned kernel inherits that interpreter, so numpy and scipy are present.

- Parameterized execution: `uv run --with papermill --with ipykernel papermill in.ipynb out.ipynb -p <key> <value> --execution-timeout 600`.
- Programmatic execution: `uv run --with nbclient jupyter execute in.ipynb --output out.ipynb`.
- `.py` percent-format and `.ipynb` interconvert: `uv run --with jupytext jupytext --to notebook script.py` and `--to py:percent notebook.ipynb`.
- Convert or export: `uv run --with nbconvert jupyter nbconvert --to {notebook,html,script} --execute in.ipynb --output out`.
- Validate: `uv run --with nbformat python -c "import nbformat,sys; nbformat.validate(nbformat.read(sys.argv[1], as_version=4))" nb.ipynb`.

For a run needing more than one tool, or one that repeats, write a PEP 723 inline-metadata script and invoke it with `uv run script.py`.

## Interactive — live kernel

Start the server with `forge-jupyter` (JupyterLab on `127.0.0.1:8888`; without a running server the MCP has nothing to drive), then operate through the `jupyter` MCP:

- Stateless run: `execute_code` runs code directly in the kernel — the simplest live executor.
- Notebook-bound: `use_notebook`, then `insert_cell` / `overwrite_cell_source` / `execute_cell` / `read_cell` / `delete_cell` / `move_cell`; `read_notebook` for the whole document; `list_kernels`, `list_notebooks`, `restart_notebook`.

The server runs on the cp312 companion lane; register a cp315 scientific kernel (`uv run --with ipykernel python -m ipykernel install --user --name scientific`) for numpy and scipy notebooks.

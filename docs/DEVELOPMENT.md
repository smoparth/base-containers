# Development Guide

This guide covers how to set up a development environment, run tests, and use the code quality tools for the ODH Base Containers project.

## Prerequisites

- Python 3.12+
- Podman (for building and testing container images)
- Git

## Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/opendatahub-io/base-containers.git
   cd base-containers
   ```

2. Create a virtual environment and install dependencies:

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -e ".[dev]"
   ```

   This installs all development dependencies (pytest, ruff, mypy, tox) defined in `pyproject.toml`.

## Code Quality

We use [ruff](https://docs.astral.sh/ruff/) for linting/formatting and [mypy](https://mypy.readthedocs.io/) for type checking. These are configured in `pyproject.toml`.

### Using tox (Recommended)

[tox](https://tox.wiki/) provides isolated environments for running checks:

```bash
# Run all checks (lint + type)
tox

# Run only linting (ruff check + format check)
tox -e lint

# Run only type checking (mypy)
tox -e type

# Auto-format code
tox -e format
```

### Running Directly

You can also run the tools directly:

```bash
# Lint check
ruff check tests/

# Format check
ruff format --check tests/

# Auto-format
ruff format tests/

# Type check
mypy tests/
```

## Building Images

Use the build script to build container images:

```bash
# Build Python image
./scripts/build.sh python

# Build CUDA image
./scripts/build.sh cuda

# Build all images
./scripts/build.sh all
```

## Running Tests

Tests require the container images to be built first and their names passed via environment variables.

### Using tox

```bash
PYTHON_IMAGE=quay.io/opendatahub/odh-midstream-python-base:3.12-ubi9 \
CUDA_IMAGE=quay.io/opendatahub/odh-midstream-cuda-base:12.8-py312 \
tox -e test
```

### Running Directly

```bash
# Run all tests
PYTHON_IMAGE=<image:tag> CUDA_IMAGE=<image:tag> pytest tests/ -v

# Run only Python image tests
PYTHON_IMAGE=<image:tag> pytest tests/test_python_image.py tests/test_common.py -v

# Run only CUDA image tests
CUDA_IMAGE=<image:tag> pytest tests/test_cuda_image.py tests/test_common.py -v
```

### Test Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PYTHON_IMAGE` | Python base image to test | `quay.io/opendatahub/odh-midstream-python-base:3.12-ubi9` |
| `CUDA_IMAGE` | CUDA base image to test | `quay.io/opendatahub/odh-midstream-cuda-base:12.8-py312` |

If an environment variable is not set, the corresponding tests will be skipped.


## CI Workflow

Before submitting a PR, ensure:

1. Code passes linting: `tox -e lint`
2. Code passes type checking: `tox -e type`
3. Tests pass for affected images


#!/usr/bin/env python3
"""Install torch (CUDA or CPU), then pinned requirements, then NeMo.

Torch/NeMo are installed outside requirements.txt so pip does not replace a
CUDA wheel with the CPU PyPI build.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

TORCH_VERSION = "2.14.0"
NEMO_VERSION = "3.0.0"
BACKPORTS_TARFILE = "backports.tarfile==1.2.0"
CUDA_INDEX = "https://download.pytorch.org/whl/cu128"
CPU_INDEX = "https://download.pytorch.org/whl/cpu"
FALLBACK_CUDA_INDEXES = (
    "https://download.pytorch.org/whl/cu126",
    "https://download.pytorch.org/whl/cu124",
)


def run(cmd: list[str]) -> None:
    print("+", " ".join(cmd), flush=True)
    subprocess.check_call(cmd)


def gpu_visible() -> bool:
    if shutil.which("nvidia-smi") is None:
        return False
    try:
        subprocess.check_call(
            ["nvidia-smi"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except (OSError, subprocess.CalledProcessError):
        return False


def python_minor() -> tuple[int, int]:
    return sys.version_info.major, sys.version_info.minor


def install_torch(use_gpu: bool) -> str:
    indexes = [CUDA_INDEX, *FALLBACK_CUDA_INDEXES] if use_gpu else [CPU_INDEX]
    last_error: Exception | None = None
    for index in indexes:
        try:
            run(
                [
                    sys.executable,
                    "-m",
                    "pip",
                    "install",
                    f"torch=={TORCH_VERSION}",
                    "--index-url",
                    index,
                ]
            )
            return index
        except subprocess.CalledProcessError as exc:
            last_error = exc
            print(f"  torch install from {index} failed; trying next index...", flush=True)
    if use_gpu:
        print("  CUDA indexes failed; falling back to CPU torch.", flush=True)
        run(
            [
                sys.executable,
                "-m",
                "pip",
                "install",
                f"torch=={TORCH_VERSION}",
                "--index-url",
                CPU_INDEX,
            ]
        )
        return CPU_INDEX
    raise SystemExit(f"Failed to install torch=={TORCH_VERSION}: {last_error}")


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    req = repo_root / "requirements.txt"
    if not req.exists():
        raise SystemExit(f"Missing {req}")

    major, minor = python_minor()
    if (major, minor) not in {(3, 10), (3, 11), (3, 12)}:
        raise SystemExit(
            f"Python {major}.{minor} is not supported. Use Python 3.10, 3.11, or 3.12."
        )

    run([sys.executable, "-m", "pip", "install", "--upgrade", "pip"])

    use_gpu = gpu_visible()
    if use_gpu:
        print(
            "NVIDIA GPU detected. Installing torch=="
            f"{TORCH_VERSION} from {CUDA_INDEX} (CUDA 12.8 wheels; "
            "compatible with CUDA 12.x/13.x hosts).",
            flush=True,
        )
        print(
            "GPU is used only for local NeMo Parakeet ASR during evaluation. "
            "The Gemini Live agent runs on Google's hosted API.",
            flush=True,
        )
    else:
        print(
            "No NVIDIA GPU detected (nvidia-smi missing or failed). "
            "Installing CPU torch=="
            f"{TORCH_VERSION} from {CPU_INDEX}.",
            flush=True,
        )
        print(
            "The agent still runs via hosted Gemini. CPU ASR is slower and may "
            "OOM on very small machines; a 48 GB NVIDIA GPU is recommended for "
            "Parakeet.",
            flush=True,
        )

    used_index = install_torch(use_gpu)
    print(f"torch index URL used: {used_index}", flush=True)

    run([sys.executable, "-m", "pip", "install", "-r", str(req)])
    run([sys.executable, "-m", "pip", "install", f"nemo-toolkit=={NEMO_VERSION}"])

    if (major, minor) == (3, 10):
        print("Python 3.10: installing backports.tarfile==1.2.0 for NeMo extract().", flush=True)
        run([sys.executable, "-m", "pip", "install", BACKPORTS_TARFILE])
    else:
        print(
            f"Python {major}.{minor}: skipping backports.tarfile (stdlib tarfile has filter=).",
            flush=True,
        )

    # Re-assert the torch pin in case nemo-toolkit pulled a different build.
    run(
        [
            sys.executable,
            "-m",
            "pip",
            "install",
            f"torch=={TORCH_VERSION}",
            "--index-url",
            used_index,
        ]
    )

    import torch

    print(
        f"torch {torch.__version__} cuda_available={torch.cuda.is_available()} "
        f"cuda_version={getattr(torch.version, 'cuda', None)}",
        flush=True,
    )
    print("Dependency installation complete.", flush=True)


if __name__ == "__main__":
    os.chdir(Path(__file__).resolve().parent.parent)
    main()

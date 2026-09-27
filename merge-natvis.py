#!/usr/bin/env python3
import os
import re
import sys
import shutil
from pathlib import Path
from datetime import datetime
import subprocess


def write_prolog(target: Path):
    now = datetime.now()
    year = f"{now.year:04d}"
    month = f"{now.month:02d}"
    day = f"{now.day:02d}"

    lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<!--',
        '- @file',
        '-',
        '- @brief Visual studio visualizer files.',
        '-',
        '- @author  Wei Tang <gauchyler@uestc.edu.cn>',
        f'- @date    {year}-{month}-{day}',
        '-',
        f'- @copyright Copyright (c) {year}.',
        '-            National Key Laboratory of Science and Technology on Communications,',
        '-            University of Electronic Science and Technology of China.',
        '-            All rights reserved.',
        '-->',
        '<AutoVisualizer xmlns="http://schemas.microsoft.com/vstudio/debugger/natvis/2010">',
    ]

    with target.open("w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def write_epilog(target: Path):
    with target.open("a", encoding="utf-8", newline="\n") as f:
        f.write("</AutoVisualizer>\n")


def merge(path: Path, target: Path):
    count = -1
    content = []

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except Exception:
        return

    for line in lines:
        if count >= 0:
            if re.search(r"</AutoVisualizer>", line):
                break

            if count == 0:
                match = re.search(
                    r'<Type Name="nsfx::([0-9a-zA-Z:]+)',
                    line
                )
                if match:
                    typ = match.group(1)
                    content.insert(0, f"<!-- {typ} -->\n")
                    count += 1

            content.append(line + "\n")

        elif re.search(r"<AutoVisualizer", line):
            count = 0

    with target.open("a", encoding="utf-8", newline="\n") as f:
        f.write("".join(content))


def copy_natvis_to(path: Path):
    print(path)

    path.mkdir(parents=True, exist_ok=True)

    files = [
        "nsfx.natvis",
        "nsfx.natstepfilter",
        "std.natstepfilter",
    ]

    for file in files:
        src = Path(file)
        if src.exists():
            shutil.copy2(src, path / file)


def install_natvis():
    home = Path.home()

    # Visual Studio Visualizers
    documents = home / "Documents"
    if documents.exists():
        for d in documents.iterdir():
            if d.is_dir() and d.name.startswith("Visual Studio "):
                copy_natvis_to(d / "Visualizers")

    # VSCode Visualizers
    vscode_ext = home / ".vscode" / "extensions"
    if vscode_ext.exists():
        for d in vscode_ext.iterdir():
            if (
                d.is_dir()
                and re.match(r"ms-vscode\.cpptools-.*-win32-.*", d.name)
            ):
                copy_natvis_to(
                    d / "debugAdapters" / "vsdbg" / "bin" / "Visualizers"
                )


def main():
    cwd = Path.cwd()

    subprocess.run([
        sys.executable,
        "make-natvis.py"
        ],
        cwd=cwd / "nsfx" / "natvis" / "intrusive",
        check=True
    )

    # Create nsfx.natvis
    target = cwd / "nsfx.natvis"

    target.touch(exist_ok=True)

    write_prolog(target)

    directories = [
        cwd / "models" / "natvis",
        cwd / "nsfx" / "natvis" / "intrusive",
        cwd / "nsfx" / "natvis",
    ]

    for natvis_dir in directories:
        if natvis_dir.exists():
            for file in natvis_dir.iterdir():
                if file.is_file() and file.suffix.lower() == ".natvis":
                    merge(file, target)

    write_epilog(target)

    print(target.read_text(encoding="utf-8"))
    print()

    # Normalize Unix line endings
    content = target.read_text(
        encoding="utf-8"
    ).replace("\r\n", "\n")

    target.write_text(
        content,
        encoding="utf-8",
        newline="\n"
    )

    install_natvis()

    input("Done. Press Enter to continue...")

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""Download packages/cache from one published ark-aur release."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import re
import shutil
import urllib.request


def release_metadata(release_id):
    headers = {"User-Agent": "ark-image", "Accept": "application/vnd.github+json"}
    if os.environ.get("GH_TOKEN"):
        headers["Authorization"] = f"Bearer {os.environ['GH_TOKEN']}"
    request = urllib.request.Request(
        f"https://api.github.com/repos/zamkara/ark-aur/releases/{release_id}",
        headers=headers,
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        release = json.load(response)
    if release["draft"] or release["prerelease"] or not release["published_at"]:
        raise ValueError("ark-aur release is not published")
    return release


def select_assets(release, kind):
    if kind == "packages":
        assets = [a for a in release["assets"] if a["name"].endswith(".pkg.tar.zst")
                  and not a["name"].rsplit("-", 3)[0].endswith("-debug")
                  and a["name"].rsplit("-", 3)[0] not in {
                      "linux-headers", "linux-zen-headers", "linux-lts-headers", "linux-hardened-headers"}]
        names = [a["name"].rsplit("-", 3)[0] for a in assets]
        if len(names) != len(set(names)):
            raise ValueError("Release contains duplicate package versions")
        missing = {"plymouth", "bootc", "bootupd", "libselinux"} - set(names)
        if missing:
            raise ValueError(f"Release missing required packages: {sorted(missing)}")
    else:
        assets = sorted(
            (a for a in release["assets"]
             if re.fullmatch(r"pacman-cache\.tar\.gz\.part-[a-z]{2}", a["name"])),
            key=lambda a: a["name"],
        )
        suffixes = [a["name"].rsplit("-", 1)[1] for a in assets]
        expected = [chr(97 + i // 26) + chr(97 + i % 26) for i in range(len(assets))]
        if suffixes != expected:
            raise ValueError("Pacman cache parts are not contiguous from aa")
    if not assets:
        raise ValueError(f"Release contains no {kind}")
    return assets


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release-id", default="latest")
    parser.add_argument("--kind", choices=["packages", "cache", "identity"], required=True)
    parser.add_argument("--destination", type=Path)
    args = parser.parse_args()
    release = release_metadata(args.release_id)
    if args.kind == "identity":
        select_assets(release, "packages")
        select_assets(release, "cache")
        with open(os.environ["GITHUB_OUTPUT"], "a") as output:
            output.write(f"sha={release['id']}\nrelease-id={release['id']}\nci=success\n")
        print(f"ark-aur release: {release['id']} published {release['published_at']}")
        return
    if args.destination is None:
        parser.error("--destination is required for downloads")
    assets = select_assets(release, args.kind)
    args.destination.mkdir(parents=True, exist_ok=True)
    def download(asset):
        name = asset["name"]
        if Path(name).name != name:
            raise ValueError(f"Invalid asset name: {name}")
        target = args.destination / name
        with urllib.request.urlopen(asset["browser_download_url"], timeout=120) as source:
            with target.open("wb") as output:
                shutil.copyfileobj(source, output)
        if target.stat().st_size != asset["size"]:
            raise ValueError(f"Incomplete download: {name}")
        print(f"Downloaded {name}", flush=True)
    with ThreadPoolExecutor(max_workers=4) as executor:
        list(executor.map(download, assets))


if __name__ == "__main__":
    main()

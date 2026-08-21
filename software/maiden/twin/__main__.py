"""CLI: `python -m maiden.twin --out DIR [--seed N] [--imperfect]`.

The pinned course interface is `maiden twin ...`; until a console-script
entry point is added to pyproject (orchestrator decision — this module
must not edit it), `python -m maiden.twin` is the same command minus the
alias, and a leading literal `twin` token is accepted so both spellings
work.
"""
import argparse
import sys

from maiden.twin.writer import write_session


def main(argv=None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] == "twin":
        argv = argv[1:]
    ap = argparse.ArgumentParser(prog="maiden twin")
    ap.add_argument("--out", required=True)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--imperfect", action="store_true")
    a = ap.parse_args(argv)
    paths = write_session(a.out, seed=a.seed, imperfect=a.imperfect)
    for k, p in paths.items():
        print(f"{k}: {p}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

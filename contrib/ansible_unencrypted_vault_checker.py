#!/usr/bin/env python
"""Check that executable text files have a shebang."""
from __future__ import absolute_import, print_function, unicode_literals

import argparse
import contextlib
import errno
import getpass
import io
import os
import pipes
import re
import select
import shutil
import stat
import subprocess
import sys
import time
from urllib.parse import urlparse

from typing import Optional, Sequence

PROJECT_DIRECTORY = os.path.realpath(os.path.curdir)

REPO = "bossjones/ansible-role-tmuxinator"


def debug_dump_exclude(obj, exclude=["__builtins__", "__doc__"]):
    for attr in dir(obj):
        if hasattr(obj, attr):
            if attr not in exclude:
                print("obj.%s = %s" % (attr, getattr(obj, attr)))

class ProcessException(Exception):
    pass


class Console:  # pylint: disable=too-few-public-methods

    quiet = False

    @classmethod
    def message(cls, str_format, *args):
        if cls.quiet:
            return

        if args:
            print(str_format % args)
        else:
            print(str_format)

        # Flush so that messages are printed at the right time
        # as we use many subprocesses.
        sys.stdout.flush()


def pquery(command, stdin=None, **kwargs):
    # SOURCE: https://github.com/ARMmbed/mbed-cli/blob/f168237fabd0e32edcb48e214fc6ce2250046ab3/test/util.py
    # Example:
    print(" ".join(command))
    proc = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs
    )
    stdout, _ = proc.communicate(stdin)

    if proc.returncode != 0:
        raise ProcessException(proc.returncode)

    return stdout.decode("utf-8")


# Directory navigation
@contextlib.contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(newdir)
    try:
        yield
    finally:
        os.chdir(prevdir)


def scm(dir=None):
    if not dir:
        dir = os.getcwd()

    if os.path.isdir(os.path.join(dir, ".git")):
        return "git"
    elif os.path.isdir(os.path.join(dir, ".hg")):
        return "hg"


def _popen(cmd_arg):
    devnull = open("/dev/null")
    cmd = subprocess.Popen(cmd_arg, stdout=subprocess.PIPE, stderr=devnull, shell=True)
    retval = cmd.stdout.read().strip()
    err = cmd.wait()
    cmd.stdout.close()
    devnull.close()
    if err:
        raise RuntimeError("Failed to close %s stream" % cmd_arg)
    return retval


def _popen_stdout(cmd_arg, cwd=None):
    # if passing a single string, either shell mut be True or else the string must simply name the program to be executed without specifying any arguments
    cmd = subprocess.Popen(
        cmd_arg,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=cwd,
        bufsize=4096,
        shell=True,
    )
    Console.message("BEGIN: {}".format(cmd_arg))
    # output, err = cmd.communicate()

    for line in iter(cmd.stdout.readline, b""):
        # Print line
        _line = line.rstrip()
        Console.message(">>> {}".format(_line.decode("utf-8")))

    Console.message("END: {}".format(cmd_arg))

def remove_file(filepath):
    os.remove(os.path.join(PROJECT_DIRECTORY, filepath))

def wait_for_enter(text="Press Enter to continue: "):
    t = input(text)
    return t

def check_has_aes256(path):  # type: (str) -> int
    ansible_vault_tagline = []

    with open(path, 'rb') as f:
        whole_file = f.readlines()

    if "ANSIBLE_VAULT;1.1;AES256" not in whole_file[0].decode("utf8"):
        print(
                '{path}: Looks like unencrypted ansible-vault files are part of the commit\n'
                "  Please encrypt them with 'ansible-vault encrypt {file_name}\n"
                .format(
                    path=path,
                    file_name=os.path.basename(path)
                ),
                file=sys.stderr,
        )
        return 1
    else:
        return 0


def main(argv=None):  # type: (Optional[Sequence[str]]) -> int
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('filenames', nargs='*')
    args = parser.parse_args(argv)

    retv = 0

    for filename in args.filenames:
        retv |= check_has_aes256(filename)

    return retv


if __name__ == '__main__':
    exit(main())

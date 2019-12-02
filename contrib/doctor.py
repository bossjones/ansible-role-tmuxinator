#!/usr/bin/env python

import os
from pathlib import Path
import subprocess

HOME_PATH = os.environ.get('HOME')

def _popen(cmd_arg, env={}):
    devnull = open("/dev/null")
    cmd = subprocess.Popen(cmd_arg, stdout=subprocess.PIPE, stderr=devnull, env=env)
    retval = cmd.stdout.read().strip()
    err = cmd.wait()
    cmd.stdout.close()
    devnull.close()
    if err:
        raise RuntimeError("Failed to close %s stream" % cmd_arg)
    return retval


class CheckSshAgentForCorpRsaKey(object):
    def run(self):
        env = {}
        assert "SSH_AGENT_PID" in os.environ
        assert "SSH_AUTH_SOCK" in os.environ
        env.update(os.environ)
        cmd = ["ssh-add", "-l"]
        ret = _popen(cmd, env=env)
        assert "rsa_corp_git" in ret.decode("utf8")

assert "HOME" in os.environ
assert "SSH_AUTH_SOCK" in os.environ

molecule_tmp_path = Path(".molecule.tmp")
ssh_dir_path = Path("{}/.ssh".format(HOME_PATH))
known_hosts_path = Path("{}/.ssh/known_hosts".format(HOME_PATH))
rsa_corp_git_path = Path("{}/.ssh/rsa_corp_git".format(HOME_PATH))
cloudops_beh_app_dev_path = Path("{}/.ssh/cloudops-beh-app-dev.pem".format(HOME_PATH))

assert molecule_tmp_path.exists()
assert ssh_dir_path.exists()
assert ssh_dir_path.is_dir()
assert known_hosts_path.exists()
assert rsa_corp_git_path.exists()
assert cloudops_beh_app_dev_path.exists()

procedure = [CheckSshAgentForCorpRsaKey()]

for step in procedure:
    step.run()

print("Hey guess what, your dev environment is ready to go!")

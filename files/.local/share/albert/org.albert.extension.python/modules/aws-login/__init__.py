from albert import *
import os
import subprocess
import copy


__title__ = "AWS Login"
__version__ = "0.1.0"
__triggers__ = "aws "
__authors__ = "Hogeyama"
__exec_deps__ = ["aws-vault"]


# Can be omitted
def initialize():
    pass


# Can be omitted
def finalize():
    pass


def handleQuery(query):
    if query.isTriggered:
        accounts = getAccounts(query)
        return [ item(a) for a in accounts ]


def getAccounts(query):
    return [
        x.split()[0] for x
        in subprocess.run(
            ['aws-vault', 'list'],
            encoding='utf-8',
            stdout=subprocess.PIPE
            ).stdout.splitlines()[2:]
        if query.string.strip() == "" or
           query.string.strip().lower() in x.lower()
    ]


def item(a):
    return Item(
            id=a,
            icon=os.path.dirname(__file__)+"/plugin.svg",
            text="AWS %s" % a,
            completion="aws %s" % a,
            actions=[ProcAction(text="TermAction", commandline=["aws-vault", "login", a])])

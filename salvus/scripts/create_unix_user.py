#!/usr/bin/env python

"""
Create a unix user and setup ssh keys.   Usage:

    create_unix_user.py [username]

If the username is not given, then a random 8-character alpha-numeric username is chosen.

If the username is given, then any -'s and characters passed the 32nd are removed from the given username.
Thus if the username is a V4 uuid, e.g., 36 characters with -'s, then the dashes are removed, giving a 32
character username, which is uniquely determined by the V4 uuid.

You should put the following in visudo:

            salvus ALL=(ALL)   NOPASSWD:  /usr/local/bin/create_unix_user.py *
            salvus ALL=(ALL)   NOPASSWD:  /usr/local/bin/delete_unix_user.py *

ALSO **IMPORTANT** put a locally built copy of .sagemathcloud (with secret deleted) in
scripts/skel to massively speed up new project creation.  You might make a symlink like this:

      sudo ln -s /home/salvus/salvus/salvus/scripts/skel .

"""

BASE_DIR='/mnt/home'

from subprocess import Popen, PIPE
import os, random, string, sys, uuid

if len(sys.argv) > 2:
    sys.stderr.write("Usage: sudo %s [optional username]\n"%sys.argv[0])
    sys.stderr.flush()
    sys.exit(1)

# os.system('whoami')

skel = os.path.join(os.path.split(os.path.realpath(__file__))[0], 'skel')
#print skel

def cmd(args):
    if isinstance(args, str):
        shell = True
        #print args
    else:
        shell = False
        #print ' '.join(args)
    out = Popen(args, stdin=PIPE, stdout=PIPE, stderr=PIPE, shell=shell)
    e = out.wait()
    stdout = out.stdout.read()
    stderr = out.stderr.read()
    if e:
        sys.stdout.write(stdout)
        sys.stderr.write(stderr)
        sys.exit(e)
    return {'stdout':stdout, 'stderr':stderr}

if len(sys.argv) == 2:
    username = sys.argv[1].replace('-','')[:32]
else:
    # Using a random username helps to massively reduce the chances of race conditions...
    alpha    =  string.ascii_letters + string.digits
    username =  ''.join([random.choice(alpha) for _ in range(8)])

out = cmd(['useradd', '-b', BASE_DIR, '-m', '-U', '-k', skel, username])

# coffeescript to determine
# BLOCK_SIZE = 4096   # units = bytes; This is used by the quota command via the conversion below.
# megabytes_to_blocks = (mb) -> Math.floor(mb*1000000/BLOCK_SIZE) + 1
# ensure host system is setup with quota for this to do anything: http://www.ubuntugeek.com/how-to-setup-disk-quotas-in-ubuntu.html

disk_soft_mb = 512 # 250 megabytes
disk_soft = disk_soft_mb * 245
disk_hard = 2*disk_soft
inode_soft = 20000
inode_hard = 2*inode_soft
cmd(["setquota", '-u', username, str(disk_soft), str(disk_hard), str(inode_soft), str(inode_hard), '-a'])

print username

# Save account info so it persists through reboots/upgrades/etc.
if os.path.exists("/mnt/home/etc/"):
    cmd("cp /etc/passwd /etc/shadow /etc/group /mnt/home/etc/")

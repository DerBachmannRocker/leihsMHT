# Upgrading from v3.45.1 to v4.19

The steps below were tested in practice in June 2018 on Debian 9.4 as both Ansible ("control") machine and Leihs server following the guide
[here](https://github.com/leihs/leihs-instance/blob/master/GUIDE.md)
In doing so I encountered a lot of unanswered questions and lacking documentation. Therefore I hereby document the steps I did to upgrade my Leihs production server.
There is no guarantee the information provided here is correct or particularly elegant. It is just the way I did things. On the positive side, what I did actually lead to a working upgraded Leihs instance.
Unfortunately, to my knowledge, the **only foolproof way** to upgrade to the current stable release is to install each and every minor version increments (ignorning smaller patch releases). In theory you could probably skip a huge number of versions, but there is no official documentation on what is tested and safe to skip. Initially following the official upgrade guide, I started with v4.11 and encountered problems with wrongly named DB columns and missing function names. Therefore I bit the bullet and installed the complete list of version increments, documenting each step, until I reached v4.19.0. I wrote a small script that makes the cloing part a bit easier. The script downloads each version into a separate directory, which makes it possible to test out the deployment on a non production machine, fix any errors you encounter specific to each version, and then play back the whole upgrade process in a short time on your production machine.

I would probably have had much less trouble had I found and read the release notes
https://github.com/leihs/leihs/blob/master/config/releases.yml
Please read the whole list of release notes before you try to install Leihs on anything than Debian 9.4 (which is what I tested the process with)

In the original upgrade guide you were instructed to first install Leihs from scratch. We will do this as well, but we will specify a specific Leihs version to clone (v4.0.0)

***Warning***: Do not upgrade your Leihs v4 installation to a higher version until after migration is done!
You need to install v4.00, because later versions changed column names in the DB and function names in the code (and the migration scripts were not updated to take care of this).

Good luck!
DerBachmannRocker

## Prerequisites
Ensure your old `v3` server is at version [3.45.1](https://github.com/leihs/leihs/releases/tag/3.45.1). For this follow the official upgrade instructions described [here](https://github.com/leihs/leihs/wiki/Upgrades).
Please make sure you have root access via SSH to both the v3 and v4 server, using public cert/key pair credentials. You need to be able to connect from your Ansible ("control") machine to both hosts with SSH, without using a password.
* Debian Version of Leihs v3 Server: I tested this process with Debian 8.10

## Ansible Setup
* Create Ansible directory: 
On the control machine (Ansible workstation), do the following:
Create a directory to hold your Ansible stuff. For example
```bash
mkdir /home/yourusername/ansibledeploy
```

* Inventory directory: 
Create a directory for your Ansible inventory and define your hosts
```bash
mkdir ~/ansibledeploy/leihshosts
mkdir ~/ansibledeploy/leihshosts/group_vars
mkdir ~/ansibledeploy/leihshosts/host_vars
mkdir ~/ansibledeploy/leihshosts/settings
```

* hosts file: 
Specify the old and new hosts accordingly. 
Create and edit the textfile `leihshosts/hosts` to have the following content:
(do not modify this. It references the other yml files further below)
```yaml
[leihs_v3_server]
leihs-v3

[leihs_server]
leihs
```
* leihs-v3.yml: 
Then create and edit `leihshosts/host_vars/leihs-v3.yml` to have the following content:
(edith every line here)
```yaml
ansible_host: yourv3leihsserver.example.com
ansible_user: root
leihs_v3_root_dir: path-to-leihs-directory-on-my-old-host
leihs_v3_ruby_dir: path-to-rbenv-version-on-my-old-host
leihs_v3_user: leihs-user-on-my-old-host
```
**leihs_v3_ruby_dir** hint: 
On your Leihs v3 Server type `which ruby`. On Debian 8 I got this result, wich worked:
/usr/local/rvm/rubies/ruby-2.3.3/bin

**leihs_v3_user** hint: 
User account with full read/write permission on leihs v3 DB. I noticed I accidentally set this to a nonexistent value and migration still succeeded.
Try 'leihs' first, as this is the default. Possibly 'root' or 'www-data' both could also be sensible values.

* leihs.yml
Create and edit `leihshosts/host_vars/leihs.yml` to point to your new v4 server:
(you only need to edit ansible_host and possibly ansible_user)
```yaml
ansible_host: yourv4leihsserver.example.com
ansible_user: root
leihs_master_secret: secret
database_dump_restore_file_path: '{{inventory_dir}}/normal.pgbin'
#this file will only be relevant from v4.15.0 and upwards
settings_file_path: '{{inventory_dir}}/settings/leihs_settings.yml'
```

* settings.yml
Create and edit 'settings/settings.yml'. This file will only be used v4.15.0 and upwards
(change everything here to fit your environment)
```yaml
smtp_address: localhost
smtp_port: 25
smtp_domain: leihs.example.com
local_currency_string: CHF
ldap_config:
mail_delivery_method: smtp
smtp_username:
smtp_password:
smtp_enable_starttls_auto: f
smtp_openssl_verify_mode: 0
time_zone: Bern
external_base_url: leihs.example.com # only used in ZHdK context
```
**time_zone** hint: Possible values for time_zone can be found [here](http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html)

* group_vars/leihs.yml
Create and edit `leihshosts/group_vars/leihs.yml`
(this contains only dashes)
```yaml
---
```

# Helper script 'leihsclone.sh'
* Create empty script file
```
touch ~/ansibledeploy/leihsclone.sh
chmod u+x ~/ansibledeploy/leihsclone.sh
```

* Edit the script to have the following content
```bash
#!/bin/bash

export rootdir="$HOME/ansibledeploy"
export referenceinventory="$HOME/ansibledeploy/leihshosts"

#all Leihs versions from 4.0.0 to 4.19.0, excluding small bugfix releases
leihsversions=(
'export leihsbranch="4.0.0";export indexnum="00";export patchssldev="true"'
#'export leihsbranch="4.1.0";export indexnum="01";export patchssldev="true"'
#'export leihsbranch="4.2.0";export indexnum="02";export patchssldev="true"'
#'export leihsbranch="4.3.1";export indexnum="03"'
#'export leihsbranch="4.4.0";export indexnum="04"'
#'export leihsbranch="4.5.1";export indexnum="05"'
#'export leihsbranch="4.6.0";export indexnum="06"'
# 'export leihsbranch="4.7.3";export indexnum="07"'
# 'export leihsbranch="4.8.0";export indexnum="08"'
# 'export leihsbranch="4.9.0";export indexnum="09"'
# 'export leihsbranch="4.10.0";export indexnum="10"'
# 'export leihsbranch="4.11.0";export indexnum="11"'
# 'export leihsbranch="4.12.0";export indexnum="12"'
# 'export leihsbranch="4.13.0";export indexnum="13"'
# 'export leihsbranch="4.14.2";export indexnum="14"'
# 'export leihsbranch="4.15.0";export indexnum="15"'
# 'export leihsbranch="4.16.1";export indexnum="16"'
# 'export leihsbranch="4.17.0";export indexnum="17"'
# 'export leihsbranch="4.18.0";export indexnum="18"'
# 'export leihsbranch="4.19.0";export indexnum="19"'
)

for i in "${leihsversions[@]}"
do
    eval $i
    export branchdir="$rootdir/$indexnum-my-leihsV$leihsbranch"
    echo "Next Leihs version: $branchdir"
    export leihsbranchint=$(echo $leihsbranch|sed 's/\.//g')
    
    git clone git@github.com:leihs/leihs.git $branchdir --branch $leihsbranch
    echo "Updating submodules"
    cd $branchdir
    pwd
    git submodule update --init --recursive
    echo "Updating submodules in 'legacy' subdirectory"
    cd $branchdir/legacy
    pwd
    git submodule update --init --recursive

    if [ "$patchssldev" == "true" ]
    then
        #patch reference to wrong openssl library
        echo "Patching reference to wrong openssl library"
        if [ "$leihsbranchint" -lt 460 ]
        then
            sed -i 's/libssl-dev/libssl1\.0-dev/g' "$branchdir/deploy/roles/ruby-install/tasks/main.yml"
            if [ "$leihsbranchint" -ge 431 ]
            then
                sed -i 's/libssl-dev/libssl1\.0-dev/g' "$branchdir/deploy/roles/ansible/tasks/install_ansible.yml"
            fi
        fi
    fi
    
    #create new inventory dir from prototype
    cp -rf $branchdir/deploy/inventories/prototype $branchdir/my-inventory
    #group vars
    rm $branchdir/my-inventory/group_vars/all.yml
    rm $branchdir/my-inventory/group_vars/leihs.yml
    ln -s $referenceinventory/group_vars/leihs.yml $branchdir/my-inventory/group_vars/leihs.yml 
    ln -s $branchdir/deploy/all.yml $branchdir/my-inventory/group_vars/all.yml
    #host vars
    rm $branchdir/my-inventory/host_vars/leihs.yml
    ln -s $referenceinventory/host_vars/leihs.yml $branchdir/my-inventory/host_vars/leihs.yml
    rm $branchdir/my-inventory/host_vars/leihs-v3.yml
    ln -s $referenceinventory/host_vars/leihs-v3.yml $branchdir/my-inventory/host_vars/leihs-v3.yml
    #hosts file
    rm $branchdir/my-inventory/hosts
    ln -s $referenceinventory/hosts $branchdir/my-inventory/hosts
    #settings file
    mkdir $branchdir/my-inventory/settings
    ln -s $referenceinventory/settings/settings.yml $branchdir/my-inventory/settings/settings.yml
done
```
# Clone the Leihs v4.0.0 git repository
Because all other versions are commented out, the script will only download v4.0.0 for now and set up symlinks to your host config files you created earlier.
```bash
cd ~/ansibledeploy
./leihsclone.sh
```
# Fixing errors during migration
Before you run your migration attempt, you should go through the following hints.

## Init-Script for rbenv on V3 server needed
You need to have `rbenv` installed on your leihsv3 server
```
apt-get install rbenv
```
And the migration script relies on a specific init-script to be present.
Create this init script with the following command on the Leihs v3 Server:
```
echo 'eval "$(rbenv init -)"' > /etc/profile.d/rbenv-load.sh
```
## Message from the devs

**IMPORTANT**: Do not change the content of `deploy/all.yml`. It does not need to be modified.

## Prevent openssl errors during ruby compilation runs
Debian 9 introduced a new version for OpenSSL as the default package, which is incompatible with Ruby 2.3.3 during compilation. OpenSSL gets omited and later causes errors.

* Fix: Replace the reference to the default package in Ansible task file (otherwise the wrong package will be reinstalled during the run)
This simple fix is done automatically by leihsclone.sh
* Manual method / check success:
edit ~/ansibledeploy/00-my-leihsV4.0.0/deploy/roles/ruby-install/tasks/main.yml
```
old: libssl-dev
new: libssl1.0-dev
```

# Installing an empty instance of v4.0.0
You are now ready to run the deployment playbook. Leihs v4.0.0 should be installed on the v4 host, but no database will be created. Run the playbook and fix any errors you encounter. Repeat until you get no error messages anymore.
**Warning**: Run the playbook from the "deploy" directory. Otherwise ansible.cfg will not be found.
```bash
cd ~/ansibledeploy/00-my-leihsV4.0.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
Depending on your console-setup, the resulting error-output might contain many lines, delimited by "\n" strings. Copy/Paste and replace these with your text editor of choice for easier readability.

Success:
```
PLAY RECAP
leihs : ok=137  changed=91   unreachable=0    failed=0
```
If you scucceeded, you can continue on to the actual data migration.

# Data migration from v3 to v4
Finally, export your data from your `v3` server and import it into the new server. I did not encounter any more errors with the migration playbook, after I fixed every problem with the install playbook. 
```
cd ~/ansibledeploy/00-my-leihsV4.0.0/deploy
ansible-playbook ./import-v3-into-v4_play.yml -i ../my-inventory/hosts -v
```
Success:
```
PLAY RECAP
leihs                      : ok=185  changed=89   unreachable=0    failed=0   
leihs-v3                   : ok=8    changed=7    unreachable=0    failed=0   
```
## LDAP
You will need to copy over your LDAP.yml from v3 to v4 for logins to work (if you do use LDAP). Local users should work immediatelly. All contracts, pictures, users, etc. will have been carried over.

# Upgrading Leihs to v4.10.0
Now the next step will be to upgrade our Leihs instance from v4.0.0 to a version that is compatible with Debian 9. This *should* be v4.6.0, but in reality v4.10.0 is the first version that truly "just works".

## Commenting-in other versions
Modifify leihsclone.sh to look like so:
```bash
...
leihsversions=(
#'export leihsbranch="4.0.0";export indexnum="00";export patchssldev="true"'
'export leihsbranch="4.1.0";export indexnum="01";export patchssldev="true"'
'export leihsbranch="4.2.0";export indexnum="02";export patchssldev="true"'
'export leihsbranch="4.3.1";export indexnum="03"'
'export leihsbranch="4.4.0";export indexnum="04"'
'export leihsbranch="4.5.1";export indexnum="05"'
'export leihsbranch="4.6.0";export indexnum="06"'
'export leihsbranch="4.7.3";export indexnum="07"'
'export leihsbranch="4.8.0";export indexnum="08"'
'export leihsbranch="4.9.0";export indexnum="09"'
'export leihsbranch="4.10.0";export indexnum="10"'
...and the rest
```
## Cloning
Run the script again to create a copy of each Leihs version locally. This will take a bit.
```bash
cd ~/ansibledeploy
./leihsclone.sh
```

## Upgrade to v4.1.0
* Run the playbook
```bash
cd ~/ansibledeploy/01-my-leihsV4.1.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP 
leihs                      : ok=136  changed=57   unreachable=0    failed=0   
```
Check for errors and continue with the next version

## Upgrade to 4.2.0"
* Run the playbook
```bash
cd ~/ansibledeploy/02-my-leihsV4.2.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP 
leihs                      : ok=136  changed=57   unreachable=0    failed=0
```
## Upgrade to 4.3.1
* Fix error during upgrade to v4.3.1 TASK [ansible : install ansible via pip]
```
fatal: [leihs]: FAILED! => {"changed": true, "cmd": "set -eux
 pip install -I --upgrade ansible==2.2.1.0", "delta": "0:00:06.748179", "end": "2018-06-26 15:32:00.823846", "msg": "non-zero return code", "rc": 139, "start": "2018-06-26 15:31:54.075667", "stderr": "+ pip install -I --upgrade ansible==2.2.1.0
Segmentation fault", "stderr_lines": ["+ pip install -I --upgrade ansible==2.2.1.0", "Segmentation fault"], "stdout": "Collecting ansible==2.2.1.0
```
* Fix: a commandline parameter causes pip to crash and kill the SSH connection. Replace syntax with parameters that do not cause the crash
(-U == --upgrade, -I == --ignore-installed)
* Edit 2 yml files:
deploy/system-prepare_play.yml
```yaml
#raw: pip install -UI pyopenssl
raw: pip install --upgrade pyopenssl
```
AND
```yaml
/deploy/roles/ansible/tasks/install_ansible.yml in both places
#pip install -I --upgrade pip
pip install --upgrade pip
...
#pip install -I --upgrade ansible=={{leihs_ansible_version}}
pip install --upgrade ansible=={{leihs_ansible_version}}
```
* Run the playbook
Be patient. Task "Gathering Facts" takes longer to complete than before.
```bash
cd ~/ansibledeploy/03-my-leihsV4.3.1/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP 
leihs                      : ok=137  changed=62   unreachable=0    failed=0
```

## Upgrade to 4.4.0
* Fix error during upgrade to v4.4.0 and v4.5.0 TASK [upgrade pyopenssl package]
* Fix: same as above. Files have not changed
Copy the fixed files
```bash
cd ~/ansibledeploy
cp ./03-my-leihsV4.3.1/deploy/system-prepare_play.yml ./04-my-leihsV4.4.0/deploy/system-prepare_play.yml
cp ./03-my-leihsV4.3.1/deploy/system-prepare_play.yml ./05-my-leihsV4.5.1/deploy/system-prepare_play.yml
```
```bash
cp ./03-my-leihsV4.3.1/deploy/roles/ansible/tasks/install_ansible.yml ./04-my-leihsV4.4.0/deploy/roles/ansible/tasks/install_ansible.yml
cp ./03-my-leihsV4.3.1/deploy/roles/ansible/tasks/install_ansible.yml ./05-my-leihsV4.5.1/deploy/roles/ansible/tasks/install_ansible.yml
```
* Run the playbook
```bash
cd ~/ansibledeploy/04-my-leihsV4.4.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP 
leihs                      : ok=141  changed=61   unreachable=0    failed=0
```
## Upgrade to 4.5.1
* Hint: After Installation of 4.5.1 you can see the version number of Leihs on the footer of the page
* Run the playbook
```bash
cd ~/ansibledeploy/05-my-leihsV4.5.1/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP
leihs                      : ok=141  changed=60   unreachable=0    failed=0 
```

## Upgrade to 4.6.0
* Fix error during upgrade to v4.6.0 TASK [ansible : install ansible via pip]
v4.6 supposedly officially supports Debian 9. We still get the pip crashes, though
```bash
#for v4.6.0 just install_ansible.yml needs fixup. Other file was fixed bei Leihs devs
cp ./03-my-leihsV4.3.1/deploy/roles/ansible/tasks/install_ansible.yml ./06-my-leihsV4.6.0/deploy/roles/ansible/tasks/install_ansible.yml
```
* Run the playbook
```bash
cd ~/ansibledeploy/06-my-leihsV4.6.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP
leihs                      : ok=140  changed=60   unreachable=0    failed=0
```

## Upgrade to 4.7.3
* Fix error during upgrade to 4.7.3 TASK [ansible : install ansible via pip]
```bash
cp ./03-my-leihsV4.3.1/deploy/roles/ansible/tasks/install_ansible.yml ./07-my-leihsV4.7.3/deploy/roles/ansible/tasks/install_ansible.yml
```
* Run the playbook
```bash
cd ~/ansibledeploy/07-my-leihsV4.7.3/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP
leihs                      : ok=140  changed=58   unreachable=0    failed=0   
```

## Upgrade to 4.8.0
* Fix error during upgrade to v4.8.0 TASK [ansible : install ansible via pip]
```bash
cp ./03-my-leihsV4.3.1/deploy/roles/ansible/tasks/install_ansible.yml ./08-my-leihsV4.8.0/deploy/roles/ansible/tasks/install_ansible.yml
```
* Run the playbook
```bash
cd ~/ansibledeploy/08-my-leihsV4.8.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP
leihs                      : ok=140  changed=57   unreachable=0    failed=0  
```

## Upgrade to 4.9.0
* Fix error during upgrade to v4.9.0 TASK [ansible : install ansible via pip]
```bash
cp ./03-my-leihsV4.3.1/deploy/roles/ansible/tasks/install_ansible.yml ./09-my-leihsV4.9.0/deploy/roles/ansible/tasks/install_ansible.yml
```
* Run the playbook
```bash
cd ~/ansibledeploy/09-my-leihsV4.9.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP
leihs                      : ok=140  changed=57   unreachable=0    failed=0   
```

## Upgrade to 4.10.0
* Just run the playbook. No fix needed.
```bash
cd ~/ansibledeploy/10-my-leihsV4.10.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
```
```
PLAY RECAP
leihs                      : ok=138  changed=57   unreachable=0    failed=0   
```
# Upgrade to latest stable 4.19.0

From here on, I encountered no errors. The deployment playbooks just worked, no fixes were needed anymore.
* v4.11.0
```bash
cd ~/ansibledeploy/11-my-leihsV4.11.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
PLAY RECAP
leihs                      : ok=138  changed=56   unreachable=0    failed=0 
```
* v4.12.0
```bash
cd ~/ansibledeploy/12-my-leihsV4.12.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
PLAY RECAP
leihs                      : ok=138  changed=56   unreachable=0    failed=0   
```
* v4.13.0
```bash
cd ~/ansibledeploy/13-my-leihsV4.13.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
PLAY RECAP
leihs                      : ok=138  changed=56   unreachable=0    failed=0   
```
* v4.14.2
```bash
cd ~/ansibledeploy/14-my-leihsV4.14.2/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
PLAY RECAP
leihs                      : ok=138  changed=56   unreachable=0    failed=0   
```
* v4.15.0
```bash
cd ~/ansibledeploy/15-my-leihsV4.15.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
PLAY RECAP
leihs                      : ok=139  changed=55   unreachable=0    failed=0   
```
* v4.16.1
```bash
cd ~/ansibledeploy/16-my-leihsV4.16.1/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
PLAY RECAP
leihs                      : ok=139  changed=57   unreachable=0    failed=0   
```
* v4.17.0
```bash
cd ~/ansibledeploy/17-my-leihsV4.17.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
PLAY RECAP
leihs                      : ok=139  changed=57   unreachable=0    failed=0   
```
* v4.18.0
```bash
cd ~/ansibledeploy/18-my-leihsV4.18.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
PLAY RECAP
leihs                      : ok=139  changed=57   unreachable=0    failed=0   
```
* v4.19.0
```bash
cd ~/ansibledeploy/19-my-leihsV4.19.0/deploy
ansible-playbook ./deploy_play.yml -i ../my-inventory/hosts -v
PLAY RECAP
leihs                      : ok=139  changed=60   unreachable=0    failed=0   
```
... and you are done!

* LDAP config
Copy over any LDAP config file you have from your old v3 installation to the new v4 server
to:
```
/leihs/legacy/config/
```

# Additional hints for fixing errors
You will probably not encounter these errors, but they caused me 3 days of work / reverse engineering. So I kept this information here for future reference, just in case. Do not apply any of the fixes listed below, except you encounter the errors described.

## Prevent error during TASK [leihs-database-install : install bundler and bundle]
cd /leihs/database
bundle install
Unable to require openssl, install OpenSSL and rebuild ruby
This error should not occur if you followed the steps regarding libssl1.0-dev above. The information is kept for reference.
Install dependencies as root, and then do a reinstall/recompile with openssl present
```
sudo apt-get install libssl1.0-dev libssl1.0.2
sudo -u leihs-database ruby-install --no-install-deps ruby 2.3.3 -- --with-openssl-dir=/usr/lib/x86_64-linux-gnu/openssl-1.0.2
```
Success: result contains line 'linking shared-object openssl.so'

## Prevent error during TASK [leihs-legacy-install : install bundler and bundle]
Unable to require openssl, install OpenSSL and rebuild ruby
Fix: same as above. Just a different service user account is involved.
```
#run dependency intall immediately before ruby-install. Ansible might have overwritten libssl with the default version via APT again
sudo apt-get install libssl1.0-dev libssl1.0.2
sudo -u leihs-legacy ruby-install --no-install-deps ruby 2.3.3 -- --with-openssl-dir=/usr/lib/x86_64-linux-gnu/openssl-1.0.2
```

## Prevent error during TASK [import-v3-into-v4 : drop existing database, create new and migrate to 100]
Task throws a huge error message, because the operation of dropping the 'production' database on Leihs v4 needs
Normally not a problem, because v4.0.0 does not create any SQL db named 'leihs' after initial install via Ansible playbook
Fix: set DISABLE_DATABASE_ENVIRONMENT_CHECK to 1
Edit `~/ansibledeploy/06-my-leihsV4.6.0/deploy/roles/import-v3-into-v4/tasks/database-clean-and-prepare.yml`
and append `export DISABLE_DATABASE_ENVIRONMENT_CHECK=1`
It should look like:
```
...
set eux
export PATH=/home/{{leihs_database_user}}/.rubies/ruby-{{leihs_database_ruby_version}}/bin:$PATH
export RAILS_ENV=production
export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
cd /leihs/database/
...
```

## Prevent error TASK [leihs-database-install : install bundler and bundle]
bin_path': can't find gem bundler
leihs-database user does not have needed permissions
You probably installed ruby as root. This causes user leihs-database to install needed gems to a protected directory.
Fix: start over and do not install Ruby as root
Or: uninstall systemwide Ruby

## Cannot migrate directly from 3.x to 4.6
I tried migrating to the earliest possible version officially supported in Debian 9.4
No luck:
```
TASK [import-v3-into-v4 : do import] ************************************************************************************************************************
fatal: [leihs]: FAILED! => {"changed": true, "cmd": "#/bin/bash
 set eux
 cd /leihs/legacy
 export PATH=/home/leihs-legacy/.rubies/ruby-2.4.2/bin:$PATH
 export RAILS_ENV=production
 export FILE=/tmp/import-v3/db_data.yml
 export ATTACHMENTS_PATH=/tmp/import-v3/public/attachments/
 export IMAGES_PATH=/tmp/import-v3/public/images/attachments/
 export PROCUREMENT_ATTACHMENTS_PATH=/tmp/import-v3/public/system/procurement/attachments/files/
 export PROCUREMENT_IMAGES_PATH=/tmp/import-v3/public/system/procurement/main_categories/images/
 bundle exec rake leihs:dbio:import", "delta": "0:00:05.746201", "end": "2018-06-26 19:37:28.480133", "msg": "non-zero return code", "rc": 1, "start": "2018-06-26 19:37:22.733932", "stderr": "rake aborted!
Set a globally unique LEIS_UUID_NS value
/leihs/legacy/lib/leihs/dbio/import.rb:6:in `singleton class'
/leihs/legacy/lib/leihs/dbio/import.rb:4:in `<module:Import>'
/leihs/legacy/lib/leihs/dbio/import.rb:3:in `<module:DBIO>'
/leihs/legacy/lib/leihs/dbio/import.rb:2:in `<module:Leihs>'
/leihs/legacy/lib/leihs/dbio/import.rb:1:in `<top (required)>'
/leihs/legacy/lib/tasks/leihs/dbio.rake:12:in `block (3 levels) in <top (required)>'
/home/leihs-legacy/.rubies/ruby-2.4.2/bin/bundle:23:in `load'
/home/leihs-legacy/.rubies/ruby-2.4.2/bin/bundle:23:in `<main>'
Tasks: TOP => leihs:dbio:import
(See full trace by running task with --trace)", "stderr_lines": ["rake aborted!", "Set a globally unique LEIS_UUID_NS value", "/leihs/legacy/lib/leihs/dbio/import.rb:6:in `singleton class'", "/leihs/legacy/lib/leihs/dbio/import.rb:4:in `<module:Import>'", "/leihs/legacy/lib/leihs/dbio/import.rb:3:in `<module:DBIO>'", "/leihs/legacy/lib/leihs/dbio/import.rb:2:in `<module:Leihs>'", "/leihs/legacy/lib/leihs/dbio/import.rb:1:in `<top (required)>'", "/leihs/legacy/lib/tasks/leihs/dbio.rake:12:in `block (3 levels) in <top (required)>'", "/home/leihs-legacy/.rubies/ruby-2.4.2/bin/bundle:23:in `load'", "/home/leihs-legacy/.rubies/ruby-2.4.2/bin/bundle:23:in `<main>'", "Tasks: TOP => leihs:dbio:import", "(See full trace by running task with --trace)"], "stdout": "Languages created: Deutsch, English (UK), English (US), Züritüütsch
Settings created: {:smtp_address=>\"localhost\", :smtp_port=>25, :smtp_domain=>\"example.com\", :local_currency_string=>\"GBP\", :contract_terms=>nil, :contract_lending_party_string=>nil, :email_signature=>\"Cheers,\", :default_email=>\"your.lending.desk@example.com\", :deliver_order_notifications=>false, :user_image_url=>nil, :logo_url=>nil, :mail_delivery_method=>\"smtp\"}", "stdout_lines": ["Languages created: Deutsch, English (UK), English (US), Züritüütsch", "Settings created: {:smtp_address=>\"localhost\", :smtp_port=>25, :smtp_domain=>\"example.com\", :local_currency_string=>\"GBP\", :contract_terms=>nil, :contract_lending_party_string=>nil, :email_signature=>\"Cheers,\", :default_email=>\"your.lending.desk@example.com\", :deliver_order_notifications=>false, :user_image_url=>nil, :logo_url=>nil, :mail_delivery_method=>\"smtp\"}"]}
```

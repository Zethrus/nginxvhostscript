# nginxvhostscript
Bash script to allow/create or delete nginx virtual hosts on Ubuntu in a single command.

## Installation ##

1. Download the script
2. Apply permission to execute:

        $ chmod +x /path/to/virtualhost.sh

3. Optional: if you want to use the script globally across users, then you need to copy the file to your /usr/local/bin directory, it is better if you copy it without the .sh extension:

        $ sudo cp /path/to/virtualhost.sh /usr/local/bin/virtualhost

### For Global Shortcut ###

        $ cd /usr/local/bin
        $ wget -O virtualhost https://raw.githubusercontent.com/Zethrus/nginxvhostscript/master/virtualhost.sh
        $ chmod +x virtualhost

## Usage ##

Basic command line syntax:

    $ sudo sh /path/to/virtualhost.sh [create | delete] [domain] [optional host_dir]

With script installed on /usr/local/bin

    $ sudo virtualhost [create | delete] [domain] [optional host_dir]


### Examples ###

To create a new virtual host:

    $ sudo virtualhost create mysite.dev

To create a new virtual host with custom directory name:

    $ sudo virtualhost create anothersite.dev my_dir

To delete a virtual host

    $ sudo virtualhost delete mysite.dev

To delete a virtual host with custom directory name:

    $ sudo virtualhost delete anothersite.dev my_dir

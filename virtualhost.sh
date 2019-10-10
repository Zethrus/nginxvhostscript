#!/bin/bash
### Set Language
TEXTDOMAIN=virtualhost

### Set default parameters
action=$1
domain=$2
rootdir=$3
owner=$(who am i | awk '{print $1}')
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
userDir='/var/www/'

if [ "$(whoami)" != 'root' ]; then
        echo $"Root permission is required to run $0.\nNon-root users can use sudo to elevate their permissions."
                exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
        then
                echo $"Your first parameter should be \"create\" or \"delete\"."
                exit 1;
fi

while [ "$domain" == "" ]
do
        echo -e $"Please provide a domain. (e.g. dev, staging)"
        read domain
done

if [ "$rootdir" == "" ]; then
        rootdir=${domain//./}
fi

if [ "$action" == 'create' ]
        then
                ### check if domain already exists
                if [ -e $sitesAvailable$domain ]; then
                        echo -e $"This domain already exists.\nPlease try a different one."
                        exit;
                fi

                ### check if directory exists or not
                if ! [ -d $userDir$rootdir ]; then
                        ### create the directory
                        mkdir $userDir$rootdir
                        ### give permission to root dir
                        chmod 755 $userDir$rootdir
                        ### write test file in the new domain dir
                        if ! echo "<?php echo phpinfo(); ?>" > $userDir$rootdir/phpinfo.php
                                then
                                        echo $"Error: Unable to write to $userDir/$rootdir/phpinfo.php.
Please check the file's permissions."
                                        exit;
                        else
                                        echo $"Added content to $userDir$rootdir/phpinfo.php."
                        fi
                fi

                ### create virtual host rules file
                if ! echo "server {
                        listen 80;

                        root $userDir$rootdir;
                        index index.php index.html index.htm;
                        server_name $domain;

                        # serve static files directly
                        location ~* \.(jpg|jpeg|gif|css|png|js|ico|html)$ {
                                access_log off;
                                expires max;
                        }

                        # removes trailing slashes (prevents SEO duplicate content issues)
                        if (!-d \$request_filename) {
                                rewrite ^/(.+)/\$ /\$1 permanent;
                        }

                        # unless the request is for a valid file (image, js, css, etc.), send to bootstrap
                        if (!-e \$request_filename) {
                                rewrite ^/(.*)\$ /index.php?/\$1 last;
                                break;
                        }

                        # removes trailing 'index' from all controllers
                        if (\$request_uri ~* index/?\$) {
                                rewrite ^/(.*)/index/?\$ /\$1 permanent;
                        }

                        # catch all
                        error_page 404 /index.php;

                        location ~ \.php$ {
                                try_files \$uri =404;
                                fastcgi_pass unix:/var/run/php5-fpm.sock;
                                fastcgi_index index.php;
                                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                                include fastcgi_params;
                        }

                        location ~ /\.ht {
                                deny all;
                        }

                }" > $sitesAvailable$domain
                then
                        echo -e $"There was an error creating the file for $domain."
                        exit;
                else
                        echo -e $"\nThe new virtual host was successfully created!\n"
                fi

                ### Add domain in /etc/hosts
                if ! echo "127.0.0.1    $domain" >> /etc/hosts
                        then
                                echo $"ERROR: Unable to write to /etc/hosts."
                                exit;
                else
                                echo -e $"Virtual host successfully added to /etc/hosts!\n"
                fi

                if [ "$owner" == "" ]; then
                        chown -R $(whoami):www-data $userDir$rootdir
                else
                        chown -R $owner:www-data $userDir$rootdir
                fi

                ### enable website
                ln -s $sitesAvailable$domain $sitesEnable$domain

                ### restart Nginx
                service nginx restart

                ### show the finished message
                echo -e $"Success!\nYou now have a new virtual host.\nYour new host is: http://$domain\nAnd
it is located at $userDir$rootdir"
                exit;
        else
                ### check whether domain already exists
                if ! [ -e $sitesAvailable$domain ]; then
                        echo -e $"This domain does not exist.\nPlease try a different one."
                        exit;
                else
                        ### Delete domain in /etc/hosts
                        newhost=${domain//./\\.}
                        sed -i "/$newhost/d" /etc/hosts

                        ### disable website
                        rm $sitesEnable$domain

                        ### restart Nginx
                        service nginx restart

                        ### Delete virtual host rules files
                        rm $sitesAvailable$domain
                fi

                ### check if directory exists or not
                if [ -d $userDir$rootdir ]; then
                        echo -e $"Delete the host's root directory? (s/n)"
                        read deldir

                        if [ "$deldir" == 's' -o "$deldir" == 'S' ]; then
                                ### Delete the directory
                                rm -rf $userDir$rootdir
                                echo -e $"Directory deleted."
                        else
                                echo -e $"Host directory conserved."
                        fi
                else
                        echo -e $"Host directory not found. Ignoring."
                fi

                ### show the finished message
                echo -e $"Success!\nThe virtual host $domain has been removed."
                exit 0;
fi

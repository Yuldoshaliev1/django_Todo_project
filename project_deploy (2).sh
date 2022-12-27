

#Requirements
# 1. git@gitlab.com:username/project.git
# 2. must be exists requirements.txt
# 3. user's username must be ubuntu in server
# 4. Django Root Dir's name must be project
# 5. Git(lab/hub, ***) ssh key


project_url=$1  # git url
project_name=$2 # project name
project_port=$3 # port

ufw allow $project_port

# make project folder && cd to project folder
cd /var/www/

# make project folder && cd to project folder
mkdir $project_name

git clone $project_url ./$project_name
cd $project_name

# Create venv
python3 -m venv venv

# Activate venv
source venv/bin/activate


pip3 install wheel
pip3 install gunicorn

# Install requirements.txt
pip3 install -r requirements.txt
python3 manage.py collectstatic --no-input

# Create Nginx file
cat >/etc/nginx/sites-available/$project_name<<EOL
server {
    listen ${project_port};
    #server_name site.uz www.site.uz;

    # location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /var/www/${project_name};
    }

    location /media/ {
        root /var/www/${project_name};
    }

    location / {
        include         proxy_params;
        proxy_pass      http://unix:/var/www/${project_name}/${project_name}.sock;
    }
}
EOL

ln -s /etc/nginx/sites-available/$project_name /etc/nginx/sites-enabled/
#end nginx settings

#gunicorn settings

cat >/etc/systemd/system/$project_name.service<<EOL
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=/var/www/${project_name}
ExecStart=/var/www/${project_name}/venv/bin/gunicorn --workers 3 --bind unix:/var/www/${project_name}/${project_name}.sock root.wsgi:application

[Install]
WantedBy=multi-user.target
EOL

systemctl start ${project_name}.service
systemctl enable ${project_name}.service
systemctl restart ${project_name}.service
systemctl restart nginx



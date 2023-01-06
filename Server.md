# Production setup steps

`apt-get update`

To prevent interruption of scripts, needrestart setting needs to be changed to automatic from interactive.
> needrestart checks which daemons need to be restarted after library upgrades.

`sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf`

`apt-get -y upgrade`

`apt-get install -y build-essential python3-dev python3-virtualenv python3-pip nginx`

`rm -rf /var/www/html/`

`cd /var/www/html/`

`git clone https://github.com/Big-Vi/wagtail-ansible-terraform.git .`

Activate virtualenv
`virtualenv env`
`source /env/bin/activate`

`pip install uwsgi`

`pip install -r requirements.txt`

  
  
Inline DB until it replaced with AWS RDS

`python manage.py migrate`  
`python manage.py createsuperuser`


> vi /var/www/html/uwsgi.ini
```
[uwsgi]
#http = 0.0.0.0:80 

chdir = /var/www/html/

module = cms.wsgi

processes = 1

master = false

vacuum = true

socket = /var/www/html/cms.sock

chmod-socket = 666

die-on-term = true

env = DJANGO_SETTINGS_MODULE=cms.settings.dev

daemonize = /var/log/uwsgi/wagtail.log
```
  
> vi /etc/nginx/sites-available/wagtail
```
upstream wagtail {
	server unix:/var/www/html/cms.sock;
}

server {

	listen 80;

	server_name 0.0.0.0;

	charset utf-8;

	# max upload size

	client_max_body_size 15M;

	# Wagtail media

	location /media {
		alias /var/www/html/cms/media;
	}

	location /static {
		alias /var/www/html/cms/static;
	}

	location / {

		include /etc/nginx/uwsgi_params;

		uwsgi_pass wagtail;

	}

}
```

`nginx -t`

`ln -s /etc/nginx/sites-available/wagtail /etc/nginx/sites-enabled/wagtail`

`systemctl restart nginx`


## Create uwsgi as a service

Run uWSGI in emperor mode.

`mkdir -p /etc/uwsgi/vassals`  
`ln -s /var/www/html/uwsgi.ini /etc/uwsgi/vassals/`

> vi /etc/systemd/system/uwsgi.service
```
[Unit]
Description=uWSGI Emperor
After=syslog.target

[Service]
ExecStart=/var/www/html/env/bin/uwsgi --emperor /etc/uwsgi/vassals
RuntimeDirectory=uwsgi
Restart=always
KillSignal=SIGQUIT
Type=notify
StandardError=syslog
NotifyAccess=all

[Install]
WantedBy=multi-user.target
```

`systemctl daemon-reload`

`systemctl start uwsgi.service`

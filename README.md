# wagtail-ansible-terraform

[Automating Wagtail CMS installation](/Server.md) using Ansible &amp; Terraform.  

## Local development setup

### Create and activate a virtual environment  

To isolate dependencies from other projects create virtual environment.  

`python3 -m venv venv`  
`source venv/bin/activate`  

### Install Wagtail

`pip install wagtail`   
`wagtail start cms`  
`pip install -r requirements.txt`  
`python3 manage.py migrate`  
`python3 manage.py createsuperuser`  
`python3 manage.py runserver`  

## Ansible
`ansible-galaxy init /infra/ansible/roles/common`

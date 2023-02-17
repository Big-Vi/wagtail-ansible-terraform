[Automating Wagtail CMS installation](/Server.md) using Ansible &amp; Terraform. IaC not only helps to restore the infrastructure when there's unintended resource deletion but also helps to document how the server is set up.  


## Local development setup

### Create and activate a virtual environment

To isolate dependencies from other projects create a virtual environment.

`python3 -m venv venv`
`source venv/bin/activate`


### Install Wagtail

`pip install wagtail`
`wagtail start cms`
`pip install -r requirements.txt`
`python3 manage.py migrate`
`python3 manage.py createsuperuser`
`python3 manage.py runserver`


## Deploying to production

When the pull request is created from any other branch to the main branch, the GitHub actions workflow runs and spins up the infrastructure in AWS using Terraform. Once the infra is set up, a dynamic inventory file would be created via terraform's template(.tpl) feature. Ansible uses this file to configure the server.  

 
## Ansible

To bootstrap roles.

`ansible-galaxy init /infra/ansible/roles/common`
`ansible-galaxy init /infra/ansible/roles/nginx`
`ansible-galaxy init /infra/ansible/roles/wagtail`

To run playbook

`ansible-playbook -i infra/ansible/inventory infra/ansible/wagtail.yml`


## Terraform

`terraform init/plan/apply/destroy`


## Setting up server using uWSGI & Nginx

The web server(Nginx) handles requests from the browser. But it can't talk to python applications. Hence uWSGI, an application server with WSGI standard, is used to serve python applications.  

I followed this [guide](https://uwsgi-docs.readthedocs.io/en/latest/tutorials/Django_and_nginx.html) to set up the server.


## Automating Terraform & Ansible using Github actions

Convert the AWS pem file to the private key and add it to GitHub secret(SSH_PRIVATE_KEY).  

`openssl rsa -in <dot-pem-file> -out aws_ssh_key`

 
### act

An [Act](https://github.com/nektos/act) is a great tool to test your GitHub actions locally hence reducing the need to push the code to Git to test the workflow.  

To get the latest code  
`arch -x86_64 brew install act --HEAD`

On M1 chip  
`docker pull --platform=linux/amd64 catthehacker/ubuntu:act-20.04`

To dry run  
`act -n`

To list workflows  
`act -l`

To make artifact upload and download work  
`act --artifact-server-path /tmp/artifacts`

  
## State backend(S3 + DynamoDB)

Terraform creates a state file(.tfstate) either locally or in a remote server to track spun-up resources and the configuration.  

When working in a team, it's possible that the state files would get out of sync. People may forget to pull the latest code from Git and it wouldn't be a good idea to store the state file in GitHub in the first place. Choosing a remote server is important since state files need to lock to prevent other team members from applying the terraform configuration at the same time.  

Backend server options:  

- Terraform cloud

- S3 + DynamoDB

- Others

I've chosen the S3 option since Terraform cloud has drawbacks. Terraform stores the dynamically generated inventory file in a remote server. Thus GitHub wouldn't have access to it to run the ansible configuration.  


## Challenges

- Saving and accessing dynamically generated inventory to run ansible-playbook is not possible with terraform cloud. So I stick to third-party state management(S3 + DynamoDB).  
- Creating and testing GitHub actions is tedious because the workflow can be tested when the code is pushed to git. there comes an act that is a nice tool to test the workflows locally.  


## TODOs

- Multiple environments with Terraform using workspaces.  
- Serve dynamic assets using AWS S3
- How to add multiple inventories with multiple ssh keys.  

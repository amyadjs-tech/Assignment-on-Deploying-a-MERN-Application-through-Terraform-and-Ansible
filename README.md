# Assignment-on-Deploying-a-MERN-Application-through-Terraform-and-Ansible
Assignment on Deploying a MERN Application through Terraform and Ansible

# Deploying a MERN Application on AWS Using Terraform and Ansible

## 1. Project Overview

This project demonstrates the deployment of a **MERN Stack Application (MongoDB, Express.js, React.js, and Node.js)** on Amazon Web Services (AWS) using **Terraform for Infrastructure as Code (IaC)** and **Ansible for configuration management and application deployment**.

The application used in this assignment is **TravelMemory**, a MERN-based travel memory management application.

The objective is to automate AWS infrastructure provisioning, configure application and database servers, implement secure networking, and deploy the application using DevOps automation tools.

### Project Information

| Parameter | Details |
|---|---|
| Project Name | TravelMemory MERN Deployment |
| Cloud Provider | Amazon Web Services (AWS) |
| AWS Region | ap-south-1 (Mumbai) |
| Infrastructure Automation | Terraform |
| Configuration Management | Ansible |
| Application Stack | MongoDB, Express.js, React.js, Node.js |
| Operating System | Ubuntu 24.04 LTS |
| EC2 Instance Type | t3.small |
| Version Control | Git and GitHub |
| Local Environment | WSL2 Ubuntu |

### GitHub Repositories

**Original MERN Application:**

https://github.com/UnpredictablePrashant/TravelMemory

**Assignment Repository:**

https://github.com/amyadjs-tech/Assignment-on-Deploying-a-MERN-Application-through-Terraform-and-Ansible

---

## 2. Project Objectives

The main objectives of this assignment are:

1. Provision AWS infrastructure using Terraform.
2. Create a custom VPC with public and private subnets.
3. Configure an Internet Gateway, NAT Gateway, and route tables.
4. Launch two EC2 instances for the application and database.
5. Configure AWS security groups and IAM roles.
6. Establish secure SSH connectivity to both EC2 instances.
7. Configure Ansible inventory and SSH ProxyCommand.
8. Install and configure MongoDB on the private EC2 instance.
9. Secure MongoDB using authentication and dedicated database users.
10. Deploy the MERN application using Ansible.
11. Configure the React frontend and Express backend.
12. Configure Nginx as a reverse proxy.
13. Verify application functionality and infrastructure connectivity.
14. Destroy AWS resources using Terraform after completing the assignment.

---

## 3. Technologies Used

| Technology | Purpose |
|---|---|
| AWS EC2 | Hosts the application and database |
| AWS VPC | Provides isolated networking |
| Public Subnet | Hosts the web server |
| Private Subnet | Hosts the MongoDB server |
| Internet Gateway | Provides internet connectivity to the public subnet |
| NAT Gateway | Provides outbound internet access to the private subnet |
| Security Groups | Controls inbound and outbound network traffic |
| IAM | Manages AWS permissions |
| Terraform | Provisions AWS infrastructure |
| Ansible | Automates server configuration |
| MongoDB | Stores application data |
| Express.js | Backend application framework |
| React.js | Frontend user interface |
| Node.js | JavaScript runtime |
| Nginx | Reverse proxy and frontend hosting |
| Git | Source code version control |
| GitHub | Remote repository hosting |
| Ansible Vault | Encrypts sensitive configuration values |

---

## 4. AWS Infrastructure Architecture

The application uses a two-tier AWS architecture with separate public and private subnets.

```text
                      INTERNET
                         |
                         |
                  Internet Gateway
                         |
                         |
                 AWS VPC (10.0.0.0/16)
                         |
          +--------------+--------------+
          |                             |
          |                             |
    PUBLIC SUBNET                 PRIVATE SUBNET
      10.0.1.0/24                   10.0.2.0/24
          |                             |
          |                             |
      Web Server                   Database Server
      Ubuntu EC2                    Ubuntu EC2
          |                             |
     React Frontend                   MongoDB
     Express Backend                 Port 27017
     Node.js
     Nginx
          |                             |
          +---------- Private ----------+
                     Connection

    NAT Gateway
         |
         +---- Outbound Internet Access
               for Private Subnet
```

### Infrastructure Components

**Public EC2 Instance**

- Hosts the React frontend and Express backend.
- Runs Node.js and Nginx.
- Accepts SSH connections only from an authorized public IP address.
- Communicates with MongoDB using the database server's private IP.

**Private EC2 Instance**

- Hosts MongoDB.
- Does not require a public IP address.
- Accepts SSH connections through the public EC2 instance.
- Accepts MongoDB connections from the authorized web server.
- Uses the NAT Gateway for outbound internet access.

**NAT Gateway**

Allows the private EC2 instance to download software updates and packages without accepting direct inbound internet connections.

---

## 5. Project Directory Structure

```text
TravelMemory-Terraform-Ansible/
|
|-- terraform/
|   |-- provider.tf
|   |-- variables.tf
|   |-- main.tf
|   |-- ec2.tf
|   |-- security.tf
|   |-- outputs.tf
|   |-- .terraform.lock.hcl
|
|-- ansible/
|   |-- ansible.cfg
|   |-- inventory.ini
|   |-- database.yml
|   |-- web.yml
|   |
|   |-- templates/
|       |-- backend.env.j2
|       |-- nginx.conf.j2
|       |-- travelmemory.service.j2
|
|-- .gitignore
|-- README.md
```

Sensitive files such as `terraform.tfvars`, Terraform state, private SSH keys, and Ansible Vault secrets are excluded from version control.

---

# PART 1 — AWS INFRASTRUCTURE USING TERRAFORM

## 6. Prerequisites

The following tools were installed in the local WSL2 Ubuntu environment:

- AWS CLI
- Terraform
- Ansible
- Git
- OpenSSH
- Python 3

### Verify Installed Tools

```bash
git --version
aws --version
terraform version
ansible --version
python3 --version
```

### Configure AWS CLI

```bash
aws configure
```

Provide the AWS access key, secret access key, default region, and output format using the secure AWS CLI configuration process.

Default region:

```text
ap-south-1
```

Verify AWS authentication:

```bash
aws sts get-caller-identity
```

Never commit AWS access keys or credentials to GitHub.

---

## 7. Terraform Initialization

Navigate to the Terraform directory:

```bash
cd ~/TravelMemory-Terraform-Ansible/terraform
```

Format Terraform files:

```bash
terraform fmt
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Preview infrastructure changes:

```bash
terraform plan
```

### Terraform Initialization Result

Terraform successfully initialized the AWS provider and validated the configuration.

---

## 8. VPC and Network Configuration

Terraform provisions the following networking resources:

- One custom VPC.
- One public subnet.
- One private subnet.
- One Internet Gateway.
- One NAT Gateway.
- One Elastic IP for the NAT Gateway.
- Public and private route tables.
- Route table associations.

### Network Configuration

| Resource | Configuration |
|---|---|
| VPC CIDR | 10.0.0.0/16 |
| Public Subnet | 10.0.1.0/24 |
| Private Subnet | 10.0.2.0/24 |
| AWS Region | ap-south-1 |
| Internet Gateway | Attached to VPC |
| NAT Gateway | Located in public subnet |

### Routing

**Public Route Table**

```text
Destination: 0.0.0.0/0
Target: Internet Gateway
```

**Private Route Table**

```text
Destination: 0.0.0.0/0
Target: NAT Gateway
```

This configuration allows public internet connectivity for the web server and outbound internet connectivity for the private database server.

---

## 9. EC2 Instance Provisioning

Terraform provisions two Ubuntu EC2 instances.

| Instance | Subnet | Purpose |
|---|---|---|
| Web Server | Public | React, Express, Node.js, Nginx |
| Database Server | Private | MongoDB |

Instance type:

```text
t3.small
```

The public EC2 instance receives a public IPv4 address.

The database instance uses only a private IPv4 address.

### Terraform Deployment

```bash
terraform apply
```

After reviewing the execution plan, confirm:

```text
yes
```

### Deployment Result

```text
Apply complete!
Resources: 24 added, 0 changed, 0 destroyed.
```

### Terraform Outputs During Deployment

| Output | Value |
|---|---|
| Web Public IP | 43.205.143.84 |
| Web Private IP | 10.0.1.188 |
| Database Private IP | 10.0.2.157 |
| VPC ID | vpc-013ad19b734739237 |

These values are historical outputs from the assignment deployment and may no longer be active.

---

## 10. AWS Security Groups

Security groups are configured to restrict access between infrastructure components.

### Web Server Security Group

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | TCP | Authorized public IP /32 | SSH administration |
| 80 | TCP | 0.0.0.0/0 | HTTP application access |

### Database Security Group

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | TCP | Web server security group | SSH through jump host |
| 27017 | TCP | Web server security group | MongoDB connectivity |

MongoDB should not be directly exposed to the public internet.

---

## 11. SSH Key Configuration

Generate an SSH key pair:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/travelmemory_key
```

Configure private key permissions:

```bash
chmod 600 ~/.ssh/travelmemory_key
```

The public key is registered with AWS through Terraform.

### Connect to Public EC2

```bash
ssh -i ~/.ssh/travelmemory_key \
  -o IdentitiesOnly=yes \
  ubuntu@<WEB_PUBLIC_IP>
```

### Connect to Private EC2 Through Public EC2

```bash
ssh -i ~/.ssh/travelmemory_key \
  -o IdentitiesOnly=yes \
  -o "ProxyCommand=ssh -i ~/.ssh/travelmemory_key -o IdentitiesOnly=yes -W %h:%p ubuntu@<WEB_PUBLIC_IP>" \
  ubuntu@<DB_PRIVATE_IP>
```

### SSH Verification

The SSH connections to both EC2 instances were tested successfully.

The public instance was used as a jump host to access the private database server.

---

# PART 2 — CONFIGURATION MANAGEMENT USING ANSIBLE

## 12. Ansible Configuration

Ansible was configured on the local WSL2 Ubuntu machine.

Create the Ansible directory:

```bash
mkdir -p ~/TravelMemory-Terraform-Ansible/ansible
cd ~/TravelMemory-Terraform-Ansible/ansible
```

### Inventory Configuration

File: `inventory.ini`

```ini
[web]
webserver ansible_host=<WEB_PUBLIC_IP>

[database]
dbserver ansible_host=<DB_PRIVATE_IP>

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/amya/.ssh/travelmemory_key
ansible_python_interpreter=/usr/bin/python3

[web:vars]
ansible_ssh_common_args='-o IdentitiesOnly=yes'

[database:vars]
ansible_ssh_common_args='-o IdentitiesOnly=yes -o ProxyCommand="ssh -i /home/amya/.ssh/travelmemory_key -o IdentitiesOnly=yes -W %h:%p ubuntu@<WEB_PUBLIC_IP>"'
```

Replace the placeholder IP addresses with the current Terraform outputs.

### Ansible Configuration File

File: `ansible.cfg`

```ini
[defaults]
inventory = inventory.ini
host_key_checking = True
timeout = 30
retry_files_enabled = False
```

### Test Ansible Connectivity

```bash
ansible all -m ping
```

### Result

```text
webserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

dbserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Both EC2 instances were successfully accessible through Ansible.

---

## 13. MongoDB Installation Using Ansible

MongoDB is installed on the private EC2 instance using the `database.yml` playbook.

The playbook performs the following operations:

1. Installs required system packages.
2. Downloads the MongoDB signing key.
3. Configures the MongoDB package repository.
4. Installs MongoDB.
5. Starts and enables the MongoDB service.
6. Creates a MongoDB administrator.
7. Creates an application-specific database user.
8. Configures MongoDB networking and authentication.
9. Restarts MongoDB to apply configuration changes.

### Install MongoDB Ansible Collection

```bash
ansible-galaxy collection install community.mongodb
```

### Run Database Playbook

```bash
ansible-playbook database.yml --ask-vault-pass
```

### MongoDB Configuration

| Parameter | Value |
|---|---|
| Database Server | Private EC2 |
| Database Port | 27017 |
| Database Name | travelmemory |
| Authentication | Enabled |
| Administration | Dedicated admin user |
| Application Access | Dedicated application user |

---

## 14. MongoDB Authentication and Ansible Vault

Sensitive MongoDB credentials are managed using Ansible Vault.

### Create Encrypted Secrets

```bash
ansible-vault create secrets.yml
```

Example variable structure:

```yaml
mongo_admin_password: "REPLACE_WITH_STRONG_ADMIN_PASSWORD"
mongo_app_password: "REPLACE_WITH_DIFFERENT_STRONG_APP_PASSWORD"
```

The actual credentials are stored in an encrypted file and excluded from the Git repository.

### View Encrypted Secrets

```bash
ansible-vault view secrets.yml
```

### Edit Encrypted Secrets

```bash
ansible-vault edit secrets.yml
```

### MongoDB Security Measures

- Dedicated MongoDB administrator.
- Separate application database user.
- Database authentication enabled.
- Private subnet deployment.
- Restricted security group access.
- Credentials stored using Ansible Vault.
- No public MongoDB endpoint.

---

## 15. PyMongo Dependency Configuration

During deployment, the application database user creation task initially failed with:

```text
You must use pymongo 4+
```

The issue was resolved by creating a Python virtual environment on the database EC2 instance and installing a compatible PyMongo version.

### Install Python Virtual Environment

```bash
ansible database -b -m apt \
  -a "name=python3-venv state=present update_cache=yes"
```

### Create Virtual Environment

```bash
ansible database -b -m command \
  -a "python3 -m venv /opt/mongodb-ansible-venv"
```

### Install PyMongo

```bash
ansible database -b -m command \
  -a "/opt/mongodb-ansible-venv/bin/pip install 'pymongo>=4,<5'"
```

### Configure Ansible Python Interpreter

The MongoDB user-management tasks use:

```yaml
vars:
  ansible_python_interpreter: /opt/mongodb-ansible-venv/bin/python
```

After fixing the dependency, the failed playbook task was resumed:

```bash
ansible-playbook database.yml \
  --start-at-task "Create application database user" \
  --ask-vault-pass
```

### Result

```text
PLAY RECAP
dbserver : ok=4 changed=3 unreachable=0 failed=0
```

---

## 16. MongoDB Service Verification

Verify that MongoDB is running:

```bash
ansible database -b -m shell \
  -a "systemctl is-active mongod"
```

### Result

```text
dbserver | CHANGED | rc=0 >>
active
```

Check the MongoDB listening port:

```bash
ansible database -b -m shell \
  -a "ss -lntp | grep 27017"
```

Verify MongoDB authentication configuration:

```bash
ansible database -b -m shell \
  -a "grep -A 2 '^security:' /etc/mongod.conf"
```

Expected authentication configuration:

```yaml
security:
  authorization: enabled
```

The MongoDB installation and service startup were successfully verified. The port-listening and authentication checks should also be included in the final deployment evidence.

---

# PART 3 — MERN APPLICATION DEPLOYMENT

## 17. Web Server Configuration

The `web.yml` Ansible playbook is intended to configure the public EC2 instance.

Its responsibilities include:

1. Installing Node.js and NPM.
2. Installing Nginx.
3. Cloning the TravelMemory repository.
4. Installing backend dependencies.
5. Configuring application environment variables.
6. Building the React frontend.
7. Configuring Nginx.
8. Creating a systemd service for the Node.js backend.
9. Starting and enabling application services.

### Application Repository

```bash
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
```

### Execute Web Server Playbook

```bash
ansible-playbook web.yml --ask-vault-pass
```

**Deployment note:** The web server playbook and its templates were created as project files. Successful execution of the web playbook and browser-level verification have not yet been established in the documented terminal results.

---

## 18. Application Environment Configuration

The backend environment configuration is generated using an Ansible Jinja2 template.

File:

```text
ansible/templates/backend.env.j2
```

The backend requires a MongoDB connection string and application-specific configuration.

Example connection string format:

```text
mongodb://<APP_USER>:<URL_ENCODED_PASSWORD>@<DB_PRIVATE_IP>:27017/travelmemory?authSource=travelmemory
```

The exact database name, authentication database, and environment variable names must match the TravelMemory backend configuration and the MongoDB users created by Ansible.

Passwords must not be hardcoded into publicly committed files.

---

## 19. Nginx Reverse Proxy

Nginx is used to serve the React frontend and forward backend API requests to the Node.js application.

Example conceptual request flow:

```text
Browser
   |
   v
Nginx :80
   |
   +---- React Frontend
   |
   +---- /api/* Requests
               |
               v
          Express Backend
               |
               v
          MongoDB :27017
```

Nginx helps provide a single HTTP entry point for the application.

The actual Nginx configuration is maintained in:

```text
ansible/templates/nginx.conf.j2
```

---

## 20. Node.js Application Service

The backend is intended to run as a systemd service.

The systemd configuration is generated using:

```text
ansible/templates/travelmemory.service.j2
```

### Verify Application Service

```bash
ansible web -b -m shell \
  -a "systemctl is-active travelmemory"
```

### Verify Nginx

```bash
ansible web -b -m shell \
  -a "systemctl is-active nginx"
```

### Check Backend Logs

```bash
ansible web -b -m shell \
  -a "journalctl -u travelmemory -n 50 --no-pager"
```

The exact service name must match the deployed systemd unit.

---

# PART 4 — APPLICATION COMPONENT COMMUNICATION

## 21. How the MERN Components Interact

The application follows a typical frontend-backend-database architecture.

### Step 1 — User Accesses the Application

The user opens the application's public URL in a browser.

The HTTP request reaches the public EC2 instance.

### Step 2 — Nginx Handles the Request

Nginx serves the React frontend or forwards API requests to the Express backend.

### Step 3 — React Communicates with Express

React sends HTTP requests to backend API endpoints.

Express processes application requests and executes the required business logic.

### Step 4 — Express Communicates with MongoDB

The backend connects to MongoDB through the database server's private IP address.

MongoDB authenticates the application user and processes database operations.

### Step 5 — Response Returns to the Browser

MongoDB returns the requested data to Express.

Express sends an API response, which React uses to update the user interface.

### Communication Summary

| Source | Destination | Purpose |
|---|---|---|
| Browser | Nginx | HTTP application access |
| Nginx | React | Frontend content |
| Nginx | Express | Backend API routing |
| Express | MongoDB | Database operations |
| Ansible Control Node | Web EC2 | SSH configuration management |
| Ansible Control Node | Database EC2 | SSH through public jump host |

---

# PART 5 — TROUBLESHOOTING

## 22. Issues Encountered and Resolutions

### Issue 1 — Terraform SSH Public Key Path Error

**Error:**

```text
Error: Invalid function argument
public_key = file(var.public_key_path)
```

**Cause:**

The configured public key path pointed to a nonexistent file.

**Resolution:**

Updated the path to:

```text
/home/amya/.ssh/travelmemory_key.pub
```

**Result:** Terraform plan completed successfully.

### Issue 2 — SSH Connection Timed Out

**Error:**

```text
ssh: connect to host <WEB_PUBLIC_IP> port 22:
Connection timed out
```

**Cause:**

The SSH security group did not allow the current public IP address.

**Resolution:**

Identified the current public IP:

```bash
curl -4 https://checkip.amazonaws.com
```

Updated the `my_ip` variable in Terraform and applied the security group change.

**Result:** Public EC2 SSH connectivity succeeded.

### Issue 3 — Private EC2 SSH Authentication Failure

**Error:**

```text
Permission denied (publickey)
```

**Cause:**

The jump-host connection did not explicitly use the correct SSH private key.

**Resolution:**

Configured SSH ProxyCommand with the appropriate private key and `IdentitiesOnly=yes`.

**Result:** Successfully connected to the private EC2 through the public EC2.

### Issue 4 — Ansible Database Host Unreachable

**Error:**

```text
dbserver | UNREACHABLE
Connection closed by UNKNOWN port 65535
```

**Cause:**

The Ansible inventory used ProxyJump without the required jump-host identity configuration.

**Resolution:**

Updated `inventory.ini` to use the working ProxyCommand.

**Result:**

```text
webserver | SUCCESS
dbserver | SUCCESS
```

### Issue 5 — Ansible Vault Decryption Failure

**Error:**

```text
Decryption failed
(no vault secrets were found that could decrypt)
```

**Cause:**

The supplied Vault password did not match the password used to encrypt the file.

**Resolution:**

Verified and corrected the Vault password configuration before rerunning the playbook.

### Issue 6 — PyMongo Version Error

**Error:**

```text
You must use pymongo 4+
```

**Cause:**

The MongoDB Ansible module required a compatible PyMongo version.

**Resolution:**

Installed PyMongo 4.x in a dedicated Python virtual environment and configured the MongoDB user tasks to use it.

**Result:** MongoDB application user creation completed successfully.

### Issue 7 — Ansible Deprecation Warnings

**Warning:**

```text
ansible.builtin.apt_repository has been deprecated
```

**Explanation:**

The installed Ansible version reported deprecation warnings for some modules and legacy imports.

**Result:** The warnings did not prevent the MongoDB playbook from completing successfully.

The deprecated modules should be updated during future maintenance.

### Issue 8 — GitHub Authentication Failure

**Error:**

```text
remote: Invalid username or token.
Password authentication is not supported for Git operations.
```

**Cause:**

GitHub rejected the HTTPS credentials used for pushing the repository.

**Recommended Resolution:**

Use a valid GitHub Personal Access Token with repository Contents read/write permission or configure GitHub CLI authentication.

A successful remote push was not confirmed in the captured terminal results.

---

# PART 6 — TESTING AND VERIFICATION

## 23. Infrastructure Verification

### Verify Terraform Resources

```bash
terraform state list
```

### Display Terraform Outputs

```bash
terraform output
```

### Verify AWS EC2 Instances

```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --query "Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]" \
  --output table
```

### Verify Ansible Connectivity

```bash
ansible all -m ping
```

### Verify MongoDB

```bash
ansible database -b -m shell \
  -a "systemctl is-active mongod"
```

### Verify Web Server

```bash
ansible web -b -m shell \
  -a "systemctl is-active nginx"
```

### Verify Application

Open the deployed application URL in a web browser and test the travel memory creation and retrieval workflows.

The final browser test should confirm that the React frontend, Express backend, and MongoDB database are communicating correctly.

---

## 24. Deployment Screenshots

The following screenshots can be included as evidence for the assignment:

| Screenshot | Description |
|---|---|
| Screenshot 1 | Terraform initialization |
| Screenshot 2 | Terraform validation and plan |
| Screenshot 3 | Terraform apply completed |
| Screenshot 4 | AWS EC2 instances |
| Screenshot 5 | VPC and subnet configuration |
| Screenshot 6 | SSH connection to public EC2 |
| Screenshot 7 | SSH connection to private EC2 |
| Screenshot 8 | Ansible ping success |
| Screenshot 9 | MongoDB installation playbook |
| Screenshot 10 | MongoDB service active |
| Screenshot 11 | Web application deployment |
| Screenshot 12 | Working TravelMemory frontend |

Add the actual screenshots to a `screenshots/` directory before referencing them in GitHub Markdown.

Screenshots 11 and 12 should only be marked completed after successful application deployment and testing.

---

# PART 7 — AWS RESOURCE CLEANUP

## 25. Destroy Infrastructure Using Terraform

After completing the assignment, AWS resources can be removed using Terraform to avoid unnecessary charges.

Navigate to the Terraform directory:

```bash
cd ~/TravelMemory-Terraform-Ansible/terraform
```

### Check Terraform State

```bash
terraform state list
```

### Preview Resource Deletion

```bash
terraform plan -destroy
```

### Destroy AWS Infrastructure

```bash
terraform destroy
```

Confirm the operation by entering:

```text
yes
```

Terraform deletes the resources it manages, including the EC2 instances, networking components, NAT Gateway, and associated managed resources.

### Verify Cleanup

```bash
terraform state list
```

An empty Terraform state indicates that no managed resources remain in that state.

Additional verification should be performed in the AWS Console to identify any resources that were created outside Terraform.

### Important

Do not delete the Terraform state files before completing the destruction process.

AWS resources may continue generating charges until deletion is completed.

---

# PART 8 — SECURITY BEST PRACTICES

## 26. Security Implementation

The project applies the following security practices:

1. **Private database subnet:** MongoDB is hosted without direct public internet exposure.
2. **Restricted SSH access:** Public EC2 SSH is limited to an authorized IP address.
3. **SSH jump host:** Private EC2 access is routed through the public instance.
4. **SSH key authentication:** Key-based authentication is used for server access.
5. **MongoDB authentication:** Database users are created with appropriate permissions.
6. **Ansible Vault:** Sensitive MongoDB passwords are encrypted.
7. **Security groups:** Network access is restricted to required ports and sources.
8. **Gitignore:** Credentials, Terraform state, and SSH private keys are excluded from the repository.
9. **IAM least privilege:** EC2 permissions should be limited to the actions required by the application.
10. **Resource cleanup:** Temporary AWS infrastructure should be removed after assignment completion.

For production environments, HTTPS, centralized secret management, monitoring, backups, and high availability should also be implemented.

---

# PART 9 — PROJECT OUTCOME

## 27. Implementation Results

The following activities were verified during the assignment:

| Activity | Result |
|---|---|
| AWS CLI configuration | Successful |
| Terraform initialization | Successful |
| Terraform validation | Successful |
| AWS infrastructure provisioning | Successful |
| VPC and subnet creation | Successful |
| Public EC2 SSH connection | Successful |
| Private EC2 SSH connection | Successful |
| Ansible inventory configuration | Successful |
| Ansible connectivity test | Successful |
| MongoDB installation | Successful |
| MongoDB administrator creation | Successful |
| MongoDB application user creation | Successful |
| MongoDB service verification | Successful |
| Web server playbook execution | Not yet verified |
| React frontend deployment | Not yet verified |
| Express backend deployment | Not yet verified |
| Browser-level application test | Not yet verified |
| GitHub push | Not yet verified |

---

## 28. Key Learnings

Through this assignment, the following DevOps concepts were practiced:

- Infrastructure as Code using Terraform.
- Automated AWS resource provisioning.
- VPC, subnet, routing, and NAT Gateway configuration.
- AWS EC2 provisioning and security groups.
- SSH key-based authentication.
- Secure access to private EC2 instances.
- Ansible inventory and playbook execution.
- Ansible Vault secret management.
- MongoDB installation and authentication.
- Python dependency troubleshooting.
- Infrastructure verification and troubleshooting.
- Git and GitHub version control.
- AWS infrastructure lifecycle management.

---

## 29. Conclusion

This project demonstrates the use of Terraform and Ansible to automate infrastructure provisioning and server configuration for a MERN application on AWS.

Terraform was successfully used to provision the AWS networking infrastructure and two EC2 instances. Ansible was configured to manage both public and private instances securely, and MongoDB was successfully installed and configured on the private database server.

The project also provided hands-on experience troubleshooting SSH authentication, Ansible connectivity, Vault decryption, and Python dependency issues.

The remaining application deployment and browser verification steps should be completed and documented before claiming a fully operational end-to-end MERN deployment.

---

## 30. References

**Terraform Documentation**

https://developer.hashicorp.com/terraform/docs

**Ansible Documentation**

https://docs.ansible.com/

**AWS Documentation**

https://docs.aws.amazon.com/

**MongoDB Documentation**

https://www.mongodb.com/docs/

**Node.js Documentation**

https://nodejs.org/

**React Documentation**

https://react.dev/

**Original TravelMemory Application**

https://github.com/UnpredictablePrashant/TravelMemory

---

## Author

**GitHub:** [amyadjs-tech](https://github.com/amyadjs-tech)

**Project:** Deploying a MERN Application on AWS Using Terraform and Ansible

**Category:** DevOps — Automation and Monitoring

**Assignment Type:** Graded DevOps Assignment

---

**Note:** This repository is intended for educational and demonstration purposes. AWS resources should be destroyed after testing to avoid unnecessary cloud charges.

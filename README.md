# chef_lab

- Supported OS: Debian, Ubuntu
- Chef Development Kit Version: 3.1.0
- chef-client version: 14.2.0, delivery version: master (6862f27aba89109a9630f0b6c6798efec56b4efe)
- berks version: 7.0.4
- kitchen version: 1.22.0
- inspec version: 2.1.72
 

## APT repository configuration
Universe repository must be enabled to install openjdk-8 package.
For Cassandra cookbook, Datastax APT repository is automatically configured, provided you enter your customer user name and key in Cassandra role:

```
 $ vi <your dir>/chef_lab/roles/cassandra.json
    ...
    "datastax_key": "<your customer key>",
    "datastax_user: "<your customer login>"
 ```
 
## Dev environment
- Install git:
```
  $ sudo apt-get update && sudo apt-get install git
```
- Install ChefDK: https://docs.chef.io/install_dk.html
- Install knife-solo:
```
  $ chef gem install knife-solo
```
- Configure your work directory for knife-solo
```
  $ knife solo init <your dir>
```
- Deploy root SSH public key from chef workstation to target hosts
- Install chef client on target hosts:
```
  $ knife solo prepare root@<target host>
```
- Go to your work directory and clone this project:
```
  $ cd <your dir>
  $ git clone https://github.com/aetile/chef_lab.git
```


## Using Apache cookbook
This role installs two website templates (contained in industrie.zip and sportz.zip archives) on the same host using name resolution on port 80 instead of proxy port redirection.
To test this role:

- Create node configuration in [your dir]/chef_lab/nodes/[hostname].json
- Update IPs in apache role [your dir]/chef_lab/roles/apache.json
- Add the following lines to name resolution on your laptop (where you will run a browser to check websites):
```
  $ vi /etc/hosts (C:\Windows\System32\Drivers\etc\hosts on Windows laptop)
  <ansible target IP> example2 example2.com www.example2.com
  <ansible target IP> example3 example3.com www.example3.com
```
- execute apache cookbook with knife-solo
```
  $ cd <your dir>/chef_lab
  $ knife solo cook root@<target node>
```
- Open a browser and test websites url http://www.example2.com and http://www.example3.com

## Using Cassandra cookbook
This role installs Datastax Enterprise and Opscenter on the cassandra inventory. As we're using knife-solo instead of a Chef server (requires a license and a complex install), you will need to run knife-solo sequentially on each cluster, beginning with seeds. Parallelizing knife-solo with xargs does not work well. To test this role:

- Create cluster nodes configuration in [your dir]/chef_lab/nodes/[hostname].json
- execute cassandra cookbook

To install or reinstall DSE and Opscenter without uninstalling run the following:
- Edit cassandra role and set "cleaninstall" parameter to "false"
```
  $ vi <your dir>/chef_lab/roles/cassandra.json
  ...
  "override_attributes": {
    "cleaninstall": "false",
```
- Execute cookbook with knife-solo sequentially on all cluster nodes, beginning with a seed node:
```
  $ cd <your dir>/chef_lab
  $ knife solo cook root@<target node>      <------ seed node
  $ knife solo cook root@<target node>
  ...
```

To uninstall and make a clean install run the following:
- Edit cassandra role and set "cleaninstall" parameter to "true"
```
  $ vi <your dir>/chef_lab/roles/cassandra.json
  ...
  "override_attributes": {
    "cleaninstall": "true",
```
- Execute cookbook with knife-solo sequentially on all cluster nodes, beginning with a seed node:
```
  $ cd <your dir>/chef_lab
  $ knife solo cook root@<target node>      <------ seed node
  $ knife solo cook root@<target node>
  ...
```
- Check cluster status:
```
  $ su - cassandra
  $ nodetool status -r
```
- Check Opscenter web UI at http://[opscenter host] or http://[opscenter host]:8888

## Cassandra cookbook with opensource Cassandra
If you need to install the Cassandra opensource version, do the following:

- Edit cassandra role and replace dse packages with cassandra package:
```
  $ vi <your dir>/chef_lab/roles/cassandra.json
```
- Edit nodes and set opscenter.enabled parameter to false:
```
  $ vi <your dir>/chef_lab/nodes/[hostname].json
  ...
  "normal": {
    "opscenter": {
      "enable": "false"
  
```
- Replace dse service start with cassandra service start in cassandra cookbook example recipe:
```
  $ vi <your dir>/chef_lab/site-cookbooks/cassandra/recipes/example.rb
```


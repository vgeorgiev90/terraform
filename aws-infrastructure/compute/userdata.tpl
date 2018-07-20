#!/bin/bash

yum install httpd -y
service httpd start

echo "Terraform provisioned instances , subnet: ${firewall_subnets}"  > /var/www/html/index.html

chkconfig httpd on



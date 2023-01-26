# SubDomainEnum
This script is a comprehensive tool for subdomain enumeration, utilizing a blend of open-source tools to achieve in-depth, accurate and speedy results. The tools employed in this script include the following:
* Subfinder
* Amass
* Puredns
* Ripgen
* crt.sh
* Assetfinder
* Interlace


## Arguments
![alt text] https://github.com/antroguy/SubDomainEnum/blob/main/images/Arguments.png

## Setup
Simply run SubDomainEnum.sh with the setup parameter.
```
./SubDomainEnum.sh setup
```

The setup process will install all necessary tools and configure your GO$ environment variables. If any of the tools or environment variables are not already installed or configured, the script will guide you through the process. The initial run will provide a list of commands for configuring your environment variables, and a subsequent run will download the necessary tools.

## Enumeration
![alt text] https://github.com/antroguy/SubDomainEnum/blob/main/images/Enumerate.png

Enumeration accepts four positional commands, three of which are required. 
 ***root_domains*** - This should be a file that contains a list of root domains (E.G. google.com, amazon.com, etc...). Each root domain should be on a new line. 
    Root Domain File EX: ```google.com
                          amazopn.com```

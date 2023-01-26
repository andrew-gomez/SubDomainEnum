#!/bin/bash
echo -e "\033[32m"
# Check if correct number of arguments were passed
if [ $# -lt 1 ]; then
    echo "Usage: $0 option [arguments]"
    echo "Options: setup, enumerate"
    echo "	   setup - Setup the environment (To include go, rust, and tools such as amasss, subfinder, assetfinder, puredns, and ripgen)"
    echo "	   enumerate - Perform subdomain enumeration" 
    exit 1
fi

# Set option and shift arguments
option=$1
shift
echo "${option} selected"


# Determine Current Shell
if echo $SHELL | grep -q "bash"; then
    RC=".bashrc"
elif echo $SHELL | grep -q "zsh"; then
    RC=".zshrc"
else
    echo "Current shell is not bash or zsh.... edit this file and replace the RC variable with your current Shell Runtime Configuration file name (E.G. .bashrc)"
    RC="REPLACE_VALUE_HERE"
fi

# Setup option 
if [ "$option" == "setup" ]; then
    mkdir -p "dist"
    sudo apt update

    #Update function for GO
    function updateGo() {
        cd dist/
        wget https://go.dev/dl/go1.19.4.linux-amd64.tar.gz
        tar -xzvf go1.19.4.linux-amd64.tar.gz
        sudo mv go /usr/lib/go-1.19
	sudo rm -f /usr/lib/go
	sudo rm -f /usr/bin/go
        sudo ln -sf /usr/lib/go-1.19/ /usr/lib/go
        sudo ln -sf /usr/lib/go-1.19/bin/go /usr/bin/go
        GO_VERSION=$(go version | awk '{print $3}')
        if [[ "$GO_VERSION" < "go1.18" ]]; then
            echo -e "\033[31mError: Failed Updating Go Version.... exiting\033[0m"
            exit 1
        fi
        cd ..
    }
    # Check if Go is installed
    if ! [ -x "$(command -v go)" ]; then
        echo -e "\033[32m"
        echo 'Installing GO'
        echo -e "\033[0m"
        sudo apt install -y golang
        if ! [ -x "$(command -v go)" ]; then
            echo -e "\033[32m"
            echo "Error: Unable to install go...."
            echo "Do you want to install go from its source code on github using this script? (yes/no)"
            read -r user_input
            echo -e "\033[0m"
            if [ "$user_input" = "yes" ] || [ "$user_input" = "y" ]; then
                updateGo
            else 
                exit 1
            fi
        fi
    fi

    # Go version needs to be atleast 1.17+
    GO_VERSION=$(go version | awk '{print $3}')
    if [[ "$GO_VERSION" < "go1.18" ]]; then
        echo -e "\033[32m"
        echo "Error: Go version is less than 1.18, please update Go and try again."
        echo "Do you want to upgrade the GO version using this script? (yes/no)"
        read -r user_input
        echo -e "\033[0m"
        if [ "$user_input" = "yes" ] || [ "$user_input" = "y" ]; then
            updateGo
        else 
            exit 1
        fi
    fi

    # Check if GOPATH is set
    if [ -z "$GOPATH" ]; then
        echo -e "\033[32m"
        echo " "
        echo 'You need to setup your go environment. perform the following and then re-run the setup:'
        echo "-------------------------------------------------------------------------------------------"
        echo "echo \"export GOROOT=/usr/lib/go\" >> ~/${RC}"
        echo "echo \"export GOPATH=\$HOME/go\" >> ~/${RC}"
        echo "echo \"export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH\" >> ~/${RC}"
        echo "source ~/${RC}"
        echo "-------------------------------------------------------------------------------------------"
        echo " "
	echo "Rerun Setup!"
      exit 1
    fi

    if ! [ -x "$(command -v make)" ]; then
        echo -e "\033[32mInstalling make...\033[0m"
        sudo apt install make
    fi
	
    # Check if jq is installed
    if ! [ -x "$(command -v jq)" ]; then
    	echo -e "\033[32m"
        echo "Installing jq...."
        echo -e "\033[0m"
        sudo apt install jq
    fi


    # Check if assetfinder is installed
    if ! [ -x "$(command -v assetfinder)" ]; then
    	echo -e "\033[32m"
        echo "Installing assetfinder..."
        echo -e "\033[0m"
        go install github.com/tomnomnom/assetfinder@latest
        if ! [ -x "$(command -v assetfinder)" ]; then
            cd dist/
            wget https://github.com/tomnomnom/assetfinder/releases/download/v0.1.1/assetfinder-linux-amd64-0.1.1.tgz
            tar -xzvf assetfinder-linux-amd64-0.1.1.tgz
            sudo mv assetfinder /usr/bin
            #Cleanup
            rm assetfinder-linux-amd64-0.1.1.tgz
            cd ..
        fi
    fi

    # Check if Subfinder is installed
    if ! [ -x "$(command -v subfinder)" ]; then
    	echo -e "\033[32m"
        echo "Installing Subfinder..."
        echo -e "\033[0m"
        go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        if ! [ -x "$(command -v subfinder)" ]; then
            cd dist/
            git clone https://github.com/projectdiscovery/subfinder.git
            cd subfinder/v2/
            sudo go mod tidy
            sudo make
            sudo cp subfinder /usr/bin/ 
            cd ../../../
        fi
    fi

    # Check if puredns is installed
    if ! [ -x "$(command -v puredns)" ]; then
    	echo -e "\033[32m"
        echo "Installing puredns..."
        echo -e "\033[0m"
        go install github.com/d3mondev/puredns/v2@latest
        if ! [ -x "$(command -v puredns)" ]; then
            cd dist
            git clone https://github.com/d3mondev/puredns.git
            cd puredns/
            sudo make
            sudo cp puredns /usr/bin/ 
            cd ../../
        fi
        cd dist/
        git clone https://github.com/blechschmidt/massdns.git
        cd massdns
        make
        sudo make install
        cd ../../

    fi

    # Check if Amass is installed
    if ! [ -x "$(command -v amass)" ]; then
    	echo -e "\033[32m"
        echo "Installing amass..."
        echo -e "\033[0m"
        go install -v github.com/OWASP/Amass/v3/...@master
        if ! [ -x "$(command -v amass)" ]; then
            cd dist/
            wget https://github.com/OWASP/Amass/releases/download/v3.21.2/amass_linux_amd64.zip
            unzip amass_linux_amd64.zip
            cd amass_linux_amd64
            sudo cp amass /usr/bin
            #Cleanup
            cd ../
            rm amass_linux_amd64.zip
        fi

    fi

    #Check amass again. If its installed with snap.... been running into issues.
    if [ -x "$(command -v amass)" ]; then
    	echo -e "\033[32m"
        echo "Checking if amass is installed via snap"
        amass_snap_package=$(which amass | grep snap)
        if [ -n "$amass_snap_package" ]; then
            echo -e "\033[32m"
            echo "Amass is already installed via snap package"
            echo "Snap may cause issues with this script while using amass if it requires root privleges. Please check before running the enumeration portion of the script."
            echo "Do you want to uninstall the snap package and download the binary from Github ? (yes/no)"
            read -r user_input
            if [ "$user_input" = "yes" ] || [ "$user_input" = "y" ]; then
                # Uninstall the snap package
                echo "uninstalling the amass snap package"
                sudo snap remove amass
                # Download the binary from Github
                echo "Downloading the amass binary from Github"
                cd dist/
                wget https://github.com/OWASP/Amass/releases/download/v3.21.2/amass_linux_amd64.zip
                unzip amass_linux_amd64.zip
                cd amass_linux_amd64
                sudo cp amass /usr/bin
                #Cleanup
                cd ../
                rm amass_linux_amd64.zip
            fi
        fi
    fi

    # Check if interlace is installed
    if ! [ -x "$(command -v interlace)" ]; then
        if ! [ -x "$(command -v python3)" ]; then
            echo -e "\033[32mInstalling python3...\033[0m"
            sudo apt install python3
            if ! [ -x "$(command -v python3)" ]; then
                echo "Error: Python3 failed to install, please install python3 and try again."
                exit 1
            fi

        fi

        if ! [ -x "$(command -v pip3)" ]; then
            echo -e "\033[32mInstalling pip3...\033[0m"
            sudo apt install python3-pip
            if ! [ -x "$(command -v pip3)" ]; then
                echo "Error: Pip3 failed to install, please install python3-pip and try again."
                exit 1
            fi

        fi
    	echo -e "\033[32m"
        cd dist/
        echo "Installing interlace..."
        echo -e "\033[0m"
        git clone https://github.com/codingo/Interlace.git
        cd Interlace;sudo python3 setup.py install
        cd ../../
    fi
 
    # Check if Rust is installed
    if ! [ -x "$(command -v puredns)" ]; then
        echo -e "\033[32m"
        echo "Installing Rust..."
        echo -e "\033[0m"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    fi

    # Check if cargo is installed
    if ! [ -x "$(command -v cargo)" ]; then
        sudo apt -y install cargo
    fi

    # Check if ripgen is installed. If not, check if rust/cargo are installed and then install it.
    if ! [ -x "$(command -v ripgen)" ]; then
        # ripgen is not installed, check if rustc and cargo are in the PATH
        if [ -x "$(command -v rustc)" ] || ! [ -x "$(command -v cargo)" ]; then
            cargo install ripgen
            echo -e "\033[32m"
            echo " "
            echo "Perform the following before running enumeration"
            echo "-------------------------------------------------------------------------------------------"
            echo "echo \"export PATH=\$HOME/.cargo/bin:\$PATH\" >> ~/${RC}"
            echo "source ~/${RC}"
            echo "-------------------------------------------------------------------------------------------"
        else
            echo "Error: Please install rust and cargo before installing ripgen."
            echo "Rerun setup after installing cargo and ripgen"
            echo " "
            exit 1
        fi
    fi
    echo -e "\033[32m"
    echo "Setup Complete!"

# Enumerate option
elif [ "$option" == "enumerate" ]; then
    # Check if correct number of arguments were passed
    if [ $# -lt 3 ]; then
     	echo -e "\033[32m"
     	echo "Usage: $0 enumerate root_domain_list wordlist outputdirectory amass_config"
     	echo "		root_domain 	(Required)	- file containing root domain names to be enumerated for subdomains"
      	echo "		wordlist 	(Required)	- wordlist used for subdomain bruteforcing"
	echo "		outputdirectory	(Required) 	- directory name that will be created for all output files to be stored."
	echo "		amass_config 	(Optional)	- amass configuration file with API keys"
      exit 1
    fi

    if ! [ -x "$(command -v interlace)" ]; then
        echo -e "\033[31mError: Interlace is required. Please run setup or install manually\033[32m" >&2
    fi

    # Check if root domain list file exists
    if [ ! -f "$1" ]; then
        echo -e "\033[31mError: domain list file does not exist\033[32m" >&2
        exit 1
    fi

    # Check if wordlist file exists
    if [ ! -f "$2" ]; then
        echo -e "\033[31mError: wordlist file does not exist\033[32m" >&2 
        exit 1
    fi

    if [ ! -e "$3" ]; then
        mkdir $3
    else 
        echo -e "\033[31mError: The specified directory already exists....\033[32m" >&2 
        exit 1
    fi
    
    # Check if config file argument is provided
    if [ $# -eq 4 ]; then
	   config_file=$4
    else
    	echo -e "\033[32m"
    	echo "Seriously? Not using an amass config? Do you even Enumerate bro?"
    	read -p "Are you sure you want to continue without providing an amass config?" -n 1 -r choice
    	echo "\n"
    	echo -e "\033[0m"
    	if [[ ! $choice =~ ^[Yy]$ ]]; then
    		rmdir $3
        	echo "Exiting script..."
        	exit 1
    	fi
	
    fi

    #Create directory structure
    mkdir -p "$3/amass" "$3/assetfinder" "$3/subfinder" "$3/crt" "$3/puredns" "$3/ripgen"

    # Create an empty array to store the list of subdomains
    declare -a subdomains
    # Check if assetfinder is installed
    if [ -x "$(command -v assetfinder)" ]; then
        # Enumerate subdomains using assetfinder
        echo -e "\033[32m"
        echo "Running assetfinder"
        echo -e "\033[0m"
        interlace -tL $1 -threads 5 -c "assetfinder _target_ > $3/assetfinder/_target_-assetfinder.txt"

    fi

    # Enumerate subdomains using crt.sh
    interlace -tL $1 -threads 5 -c "curl -s 'https://crt.sh/?q=%._target_&output=json' -A 'Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0' | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > $3/crt/_target_-crt.txt"
    interlace -tL $1 -threads 5 -c "curl -s 'https://crt.sh/?cn=%._target_&output=json' -A 'Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0' | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > $3/crt/_target_cn-crt.txt"
    
    # Check if Subfinder is installed
    if [ -x "$(command -v subfinder)" ]; then
        # Enumerate subdomains using Subfinder
        echo -e "\033[32m"
        echo "Running Subfinder"
        echo -e "\033[0m"
        interlace -tL $1 -threads 5 -c "subfinder -d _target_ -o $3/subfinder/_target_-subfinder.txt"
    else
        echo -e "\033[31mError: Skipping Subfinder, not installed\033[32m" >&2 
    fi

    # Check if puredns is installed
    if [ -x "$(command -v puredns)" ]; then
        # Create resolvers.txt for puredns
        echo "8.8.8.8" > $3/puredns/resolvers.txt
        echo "8.8.4.4" >> $3/puredns/resolvers.txt
        echo "208.67.222.222" >> $3/puredns/resolvers.txt
        echo "208.67.220.220" >> $3/puredns/resolvers.txt
        # Bruteforce additional subdomains using PureDNS
        interlace -tL $1 -threads 5 -c "puredns bruteforce $2 _target_ -r $3/puredns/resolvers.txt > $3/puredns/_target_-puredns.txt"

    else
        echo -e "\033[31mError: Skipping puredns, not installed\033[32m" >&2 
    fi

    # Combine the results from all three tools
    cat $3/assetfinder/* $3/crt/* $3/subfinder/* $3/puredns/*puredns.txt | sort -u >> "$3/All_subdomains.txt"

    # Add the subdomains to the array
    while read subdomain; do
       subdomains+=($subdomain)
    done < "$3/All_subdomains.txt"

    # Check if amass is installed
    if [ -x "$(command -v amass)" ]; then
    	if [ $# -ge 4 ]; then
    		echo -e "\033[32m"
    		echo "Running amass with config"
    		echo -e "\033[0m"
    		amass enum -v --active -nf "$3/All_subdomains.txt" -df $1 -dir $3/amass/ -config $4
    		subdomains+=($(cat $3/amass/*.txt))
    	else
		# Enumerate additional subdomains using Amass
		echo -e "\033[32m"
		echo "Running amass without config"
		echo -e "\033[0m"
		amass enum -v --active -nf "$3/All_subdomains.txt" -df $1 -dir $3/amass/
		subdomains+=($(cat $3/amass/*.txt))
	fi

    else
        echo -e "\033[31mError: Skipping amass, not installed\033[32m" >&2 
    fi

    # Sort the array of subdomains and remove duplicates
    sorted_subdomains=($(printf "%s\n" "${subdomains[@]}" | sort -u))
    # Check if ripgen is installed
    if [ -x "$(command -v ripgen)" ]; then
        # Use current array of subdomains as input to ripgen to perform permutation bruteforcing
        ripgen -d $3/amass/*.txt > $3/ripgen/ripgen_wordlist.txt
        if [ ! -e $3/ripgen/ripgen_wordlist.txt ]; then
          echo -e "\033[31mError: The ripgen file does not exist... skipping permutated domain enumeration\033[32m" >&2 
        else
            if [ ! -s $3/ripgen/ripgen_wordlist.txt ]; then
                echo -e "\033[31mError: The ripgen output was empty... skipping permutated domain enumeration\033[32m" >&2 
            else
            	echo -e "\033[32m"
                echo "Running puredns to identify and resolve valid permutated domains"
                echo -e "\033[0m"
                # Use the output from ripgen as input to puredns to check for valid domains
                permutated_domains=$(puredns resolve -r $3/puredns/resolvers.txt $3/ripgen/ripgen_wordlist.txt)
                # Convert the string to an array
                IFS=$'\n' read -d '\n' -ra permutated_domains_array <<< "$permutated_domains"

                #Save to Disk
                printf "%s\n" "${permutated_domains[@]}" > $3/ripgen/permutated_domains.txt

                # Create an empty array to store the results
                declare -a result
                # Iterate over the elements of array2
                for domain in "${permutated_domains_array[@]}"; do
                        found=0
                        for i in "${sorted_subdomains[@]}"; do
                            if [ "$i" == "$domain" ]; then
                                found=1
                                break
                            fi
                        done

                        # If the domain was not found in array1, add it to the result array
                        if [ $found -eq 0 ]; then
                            result+=("$domain")
                        fi
                done

                #Add new results to amass db
                if [ ${#result[@]} -eq 0 ]; then
                    echo -e "\033[32m"
                    echo "The permutated result array is empty, no new sub domains where identified through permutation."
                else 
                    printf "Newly identified permutated domains: %s\n" "${result[@]}"
                    printf "%s\n" "${result[@]}" > $3/ripgen/temp_newDomains.txt
                    # This will only add new domains to the amass db for tracking, no scanning will be conducted. 
                    amass enum -passive  -df $3/ripgen/temp_newDomains.txt -nf $3/ripgen/permutated_domains.txt -incluide " "

                fi
                # Add the final list of subdomains to the subdomains variable
                sorted_subdomains+=(${permutated_domains[@]})
            fi   
        fi       

    else
        echo -e "\033[31mError: Skipping ripgen, not installed\033[32m" >&2 
    fi

    unsorted_final_subdomains=($(sort -u <<< "${sorted_subdomains[*]}"))
    #Save the final list to disk
    echo -e "\033[32m"
    printf "%s\n" "${unsorted_final_subdomains[@]}" > $3/unsorted_final_subdomains.txt
    final_subdomains=$(cat "$3/unsorted_final_subdomains.txt" | sort -u)
    printf "%s\n" "${final_subdomains}" > $3/final_subdomains.txt
    echo "-------------------Final List of SubdDomains ---------------------------------------"
    printf "%s\n" "${final_subdomains}"
    rm "$3/All_subdomains.txt"
    rm "$3/unsorted_final_subdomains.txt"
else
    echo -e "\033[32m"
    echo "Usage: $0 option [arguments]"
    echo "Options: setup, enumerate"
    echo "	   setup - Setup the environment (To include go, rust, and tools such as amasss, subfinder, assetfinder, puredns, and ripgen)"
    echo "	   enumerate - Perform subdomain enumeration" 
    echo -e "\033[31mError: Invalid option provided...\033[32m" >&2 
    exit 1
fi

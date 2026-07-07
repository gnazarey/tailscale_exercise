Overview
-----------------
I will be demonstrating Tailscale's ability to establish a unified network mesh 
connecting multiple client nodes back to a central server. Each participating 
machine is deliberately located in separate, distinct data centers. This 
multi-datacenter setup models real-world complex environments, such as hybrid 
cloud deployments or global enterprise architectures that require secure 
connectivity across varied jurisdictional boundaries and disparate cloud 
providers.

Why this use case?
-----------------
I chose this specific use case because it validates Tailscale's effectiveness 
in tackling these highly complex, decentralized networking challenges. The 
requirement for establishing secure connectivity between a main datacenter 
server and multiple remote client nodes is not only technically practical but 
represents the most common operational challenge faced by modern enterprises. 
Furthermore, since the application incorporates comprehensive system monitoring, 
I am providing an immediately applicable model that addresses critical business 
needs for robust, cross-site observability.
 
Architecture Overview
---------------------
            ┌─────────────┐             
       ┌────┤HQ DataCenter├──────┐      
       │    └─────────────┘      │      
       │                         │      
       │                         │      
┌──────┴──────┐          ┌───────┴─────┐
│CA DataCenter│          │US DataCenter│
└─────────────┘          └─────────────┘
Server Node is in the HQ DataCenter
Client Node is in the CA and US DataCenter 

Setup and Deployment Instructions
--------------------------------
Download the Lab_Image_Ubuntu_26_04_LTS.ova from https://drive.google.com/file/d/1fhGBCAeDdqW8C5ZDeGK-Ua_wEUmmoj0o/view?usp=drive_link

ESXi Installation
Create a new machine using the Lab_Image_Ubuntu_26_04_LTS.ova 
1. Selection Creation Type
	- Deploy a virtual machine from an OVF or OVA File
	- Click Next
2. Select OVF and VMDK files
	- Name the virtual machine - parent_server
	- Select and copy the OVA to the ESXi
	- Click Next
3. Select Storage
	- Select a datastore that has at least 60GB free
	- Click Next
4. Deployment options
	- Select a network mapping that has internet access
	- Select Thin disk provisioning
	- Uncheck Power on Automatically
	- Click Next
5. Ready to complete
	- Review the configure to make sure there are no mistakes
	- There will be an error message that pop-up. Ignore it for now.
	- Click Finish

Create a new machine using the Lab_Image_Ubuntu_26_04_LTS.ova 
1. Selection Creation Type
	- Deploy a virtual machine from an OVF or OVA File
	- Click Next
2. Select OVF and VMDK files
	- Name the virtual machine - client01
	- Select and copy the OVA to the ESXi
	- Click Next
3. Select Storage
	- Select a datastore that has at least 60GB free
	- Click Next
4. Deployment options
	- Select a network mapping that has internet access
	- Select Thin disk provisioning
	- Uncheck Power on Automatically
	- Click Next
5. Ready to complete
	- Review the configure to make sure there are no mistakes
	- There will be an error message that pop-up. Ignore it for now.
	- Click Finish

Repeat the above step for each remote data location.


User Accounts:
labuser		D0ntT311@ny0n3 - user has sudo privileges


Wait until the ova file has been uploaded. The status can be monitored in the recent task area.
Once Import VAPP and Upload disk - Lab_Image_Ubuntu_26_04_LTS-disk1.vmdk have completed, power the vm on.
Since SSHD is running your can ssh to the host. You can get the ip information under the General Information Networking.

Install files:
Configuration File: https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/install_config.sh
Installation File: https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/installation.sh

## Lab Server configuration
cd /tmp
/usr/bin/wget https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/install_config.sh
/usr/bin/wget https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/installation.sh
Edit install_config.sh with your favorite editor
	- Change HOSTNAME to server
	- Change TAILSCALE_AUTH_KEY to the key created
Make sure you are in the /tmp directory
run this command: bash installation.sh -u

## Lab Client configuration
cd /tmp
/usr/bin/wget https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/install_config.sh
/usr/bin/wget https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/installation.sh
Edit install_config.sh with your favorite editor
	- Change HOSTNAME to client
	- Change TAILSCALE_AUTH_KEY to the key created
	- Copy the Parent IP from the install_config.sh file on the server
	- Copy the API_KEY from the install_config.sh file on the server
Make sure you are in the /tmp directory
run this command: bash installation.sh -c

How to Validate that it works?
------------------------------

Any Assumptions or prerequisities?
------------------------------
The following assumptions and prerequisities were made: 
	- access to a vm platform that can run ova images
	- each of the vms would have access to the internet
	- each of the locations could support the following vm specs:
			OS Ubuntu Linux 26.04 LTS
			CPU Count: 4
			RAM: 4GB
			Disk: 50GB	

What worked well
----------------
Two major factors contributed to the project's efficiency and accelerated 
timeline. Regarding system architecture, starting with a minimal Ubuntu Server 
image ensured optimal resource utilization and system footprint. The utilized 
software platforms were particularly effective because their installation 
scripts successfully bundled all required resources and dependencies. This 
pre-packaged approach allowed me to bypass extensive manual research cycles 
and reduce time spent on complex trial-and-error configuration. Furthermore, 
leveraging Tailscale’s capability for outbound connections meant that network 
connectivity could be established without requiring any modifications or 
exceptions to the firewalls at each deployment location, greatly streamlining 
the integration process.

What was difficult or surprising
--------------------------------

What you would do differently with more time
--------------------------------------------
With additional time, my focus would be on enhancing the platform's scalability
and deepening its security architecture. Specifically, I would prioritize 
three key areas of improvement:
1.	Operational Scalability: I would expand the current deployment model to 
		support multiple client integrations at each physical location. This 
		expansion would also involve leveraging advanced networking features like 
		Tailscale exit-nodes and regional routing capabilities to optimize 
		connectivity and minimize latency across diverse geographic deployments.
2.	Security Posture Enhancement: Implementing robust device posturing 
		capabilities is critical. This feature would allow me to enforce granular 
		security compliance checks at the access layer, significantly strengthening
		the overall network perimeter.
3.	Workflow Efficiency: Finally, improving client configuration management by 
		adding the Send Files feature to streamline the onboarding and deployment 
		process, making it easier for the parent node to securely transfer the 
		configuration files.

Where, if anywhere, you used AI assistance?
--------------------------------------------
AI assistance was employed in two primary capacities. I used it to refine the 
overall quality and polish the documentation, ensuring maximum clarity and 
consistency. Additionally, I utilized AI resources to aid in the comprehension 
and understanding of the technical specifications for the Tailscale API.
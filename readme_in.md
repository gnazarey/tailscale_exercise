# Tailscale Multi-Datacenter Network Mesh Demonstration

## Overview

I will be demonstrating Tailscale's ability to establish a unified network mesh connecting multiple client nodes back to a central server. Each participating machine is deliberately located in separate, distinct data centers. This multi-datacenter setup models real-world complex environments, such as hybrid cloud deployments or global enterprise architectures that require secure connectivity across varied jurisdictional boundaries and disparate cloud providers.

## Why This Use Case?

I chose this specific use case because it validates Tailscale's effectiveness in tackling these highly complex, decentralized networking challenges. The requirement for establishing secure connectivity between a main datacenter server and multiple remote client nodes is not only technically practical but represents the most common operational challenge faced by modern enterprises. Furthermore, since the application incorporates comprehensive system monitoring, I am providing an immediately applicable model that addresses critical business needs for robust, cross-site observability.

## Architecture Overview

```
            ┌─────────────┐             
       ┌────┤HQ DataCenter├──────┐      
       │    └─────────────┘      │      
       │                         │      
       │                         │      
┌──────┴──────┐          ┌───────┴─────┐
│CA DataCenter│          │US DataCenter│
└─────────────┘          └─────────────┘
```

**Server Node**: Located in the HQ DataCenter  
**Client Nodes**: Located in the CA and US DataCenters  

## Setup and Deployment Instructions

### ESXi Installation

Create a new machine using the `Lab_Image_Ubuntu_26_04_LTS.ova`

#### PARENT CONFIGURATION

1. **Selection Creation Type**
   - Deploy a virtual machine from an OVF or OVA File
   - Click Next

2. **Select OVF and VMDK files**
   - Name the virtual machine - `parent_server`
   - Select and copy the OVA to the ESXi
   - Click Next

3. **Select Storage**
   - Select a datastore that has at least 60GB free
   - Click Next

4. **Deployment options**
   - Select a network mapping that has internet access
   - Select Thin disk provisioning
   - Uncheck Power on Automatically
   - Click Next

5. **Ready to complete**
   - Review the configuration to make sure there are no mistakes
   - There will be an error message that pop-up. Ignore it for now.
   - Click Finish

### CLIENT CONFIGURATION

Create a new machine using the `Lab_Image_Ubuntu_26_04_LTS.ova`

1. **Selection Creation Type**
   - Deploy a virtual machine from an OVF or OVA File
   - Click Next

2. **Select OVF and VMDK files**
   - Name the virtual machine - `client01`
   - Select and copy the OVA to the ESXi
   - Click Next

3. **Select Storage**
   - Select a datastore that has at least 60GB free
   - Click Next

4. **Deployment options**
   - Select a network mapping that has internet access
   - Select Thin disk provisioning
   - Uncheck Power on Automatically
   - Click Next

5. **Ready to complete**
   - Review the configuration to make sure there are no mistakes
   - There will be an error message that pop-up. Ignore it for now.
   - Click Finish

Repeat the above steps for each remote data location.

### User Accounts
```
labuser     D0ntT311@ny0n3 - user has sudo privileges
```

Wait until the OVA file has been uploaded. The status can be monitored in the recent task area.
Once Import VAPP and Upload disk - `Lab_Image_Ubuntu_26_04_LTS-disk1.vmdk` have completed, power the VM on.
Since SSHD is running you can SSH to the host. You can get the IP information under the General Information Networking.

### Install Files

- **Configuration File**: https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/server_config.sh
- **Installation File**: https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/install.sh

### Lab Parent Configuration

Login as `labuser` with the given credentials. In the user's home directory perform the following actions:

```bash
/usr/bin/wget https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/server_config.sh
/usr/bin/wget https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/install.sh
```

Edit `server_config.sh` with your favorite editor:
- Change HOSTNAME to `server`
- Change TAILSCALE_AUTH_KEY to the key created

Run this command: `bash install.sh -u`

When the script has completed, make sure to copy the `client_config.sh` to the client machines.

### Lab Client Configuration

Login as `labuser` with the given credentials. In the user's home directory perform the following actions:

```bash
/usr/bin/wget https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/install.sh
```

Either copy the `client_config.sh` file or create it with the output from the server script in the home directory.

Edit `client_config.sh` with your favorite editor:
- Change HOSTNAME to `client`
- Check the values of TAILSCALE_AUTH_KEY, Parent_IP, and API_KEY to make sure they match what is in `server_config.sh` on the parent machine

Run this command: `bash install.sh -c`

## How to Validate That It Works?

To thoroughly validate that the system is connected and operating correctly within the Tailscale environment, please use the following diagnostic procedures:

### 1. Console Validation (GUI Check)
Verify connectivity by checking the host entry within the console's Machines tab. The presence of a successful host entry confirms basic network integration.

### 2. Command Line Interface (CLI) Diagnostics
For advanced and detailed troubleshooting, use the following CLI methods:

- **Basic Status Check**: Run `tailscale status` to view the current connection state and assigned IPs for all nodes.
- **Detailed Network Analysis (Recommended)**: For a comprehensive assessment of both local and Tailscale networking, utilize the provided script `network_connectivity.sh`. This requires three steps:

  a. Log into the CLI session.
  
  b. Download the script using wget:
     ```bash
     wget https://raw.githubusercontent.com/gnazarey/tailscale_exercise/refs/heads/main/network_connectivity.sh
     ```
  
  c. Execute the script using bash:
     ```bash
     bash network_connectivity.sh
     ```

### 3. Application Layer Validation (Web Interface)
To confirm that the application layer is successfully recognizing connected hosts:

- Navigate to the dashboard at `http://<PARENT_IP>:19999`
- Click Skip and utilize the anonymous dashboard access feature. This action redirects you to the main console view.
- Select Nodes from the navigation menu. This section displays a real-time list of all connected nodes that are actively communicating with the system.

## Assumptions and Prerequisites

Please note that the following assumptions and prerequisites were utilized in the development of this plan/design:

### I. Platform and Access Requirements (Prerequisites)
- **Networking Solution**: The user must possess an existing Tailscale account, or be capable of establishing one immediately upon project commencement.
- **Virtualization Environment**: Operational access to a Virtual Machine (VM) platform is required that supports the deployment of OVA images.
- **Connectivity**: All deployed virtual machines must maintain reliable outbound internet connectivity.

### II. Resource and Infrastructure Assumptions
The following specifications are assumed for all deployment locations:

- **Operating System**: Ubuntu Linux 26.04 LTS
- **Computational Resources (Per VM)**:
  - CPU Count: 4 Cores
  - RAM: 4 GB
  - Storage: 50 GB Disk Space

## What Worked Well

Two major factors contributed to the project's efficiency and accelerated timeline. Regarding system architecture, starting with a minimal Ubuntu Server image ensured optimal resource utilization and system footprint. The utilized software platforms were particularly effective because their installation scripts successfully bundled all required resources and dependencies. This pre-packaged approach allowed me to bypass extensive manual research cycles and reduce time spent on complex trial-and-error configuration. Furthermore, leveraging Tailscale's capability for outbound connections meant that network connectivity could be established without requiring any modifications or exceptions to the firewalls at each deployment location, greatly streamlining the integration process.

## What Was Difficult or Surprising

I did not encounter significant difficulties during the process. However, what was particularly surprising and noteworthy was the exceptional ease of use regarding the Tailscale platform and its associated tools. The combination of thorough documentation and high-quality online video tutorials provided clear, comprehensive explanations that facilitated a smooth setup, configuration, and overall workflow.

## What You Would Do Differently with More Time

With additional time, my focus would be on enhancing the platform's scalability and deepening its security architecture. Specifically, I would prioritize three key areas of improvement:

1. **Operational Scalability**: Expand the current deployment model to support multiple client integrations at each physical location. This expansion would also involve leveraging advanced networking features like Tailscale exit-nodes and regional routing capabilities to optimize connectivity and minimize latency across diverse geographic deployments.

2. **Security Posture Enhancement**: Implementing robust device posturing capabilities is critical. This feature would allow me to enforce granular security compliance checks at the access layer, significantly strengthening the overall network perimeter.

3. **Workflow Efficiency**: Improving client configuration management by adding the Send Files feature to streamline the onboarding and deployment process, making it easier for the parent node to securely transfer the configuration files.

## Where, If Anywhere, You Used AI Assistance

AI assistance was employed in two primary capacities. I used it to refine the overall quality and polish the documentation, ensuring maximum clarity and consistency. Additionally, I utilized AI resources to aid in the comprehension and understanding of the technical specifications for the Tailscale API.
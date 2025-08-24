# PS Lab: Salesforce Permissions Analyzer

- [What is PS Lab](#what-is-ps-lab)
- [Key Features](#key-features)
- [What is not supported (Yet)](#what-is-not-supported-yet)
- [Pre-Installation Setup Guide](#pre-installation-setup-guide)
   * [Step 1: Create an External Client App](#step-1-create-an-external-client-app)
   * [Step 2: Create an Authentication Provider](#step-2-create-an-authentication-provider)
   * [Step 3: Update the Callback URL in the External Client App](#step-3-update-the-callback-url-in-the-external-client-app)
   * [Step 4: Create an External Credentials](#step-4-create-an-external-credentials)
   * [Step 5: Create a Named Credential](#step-5-create-a-named-credential)
- [Installation](#installation)
- [Post-Installation Setup Guide](#post-installation-setup-guide)
- [Walkthrough](#walkthrough)
- [Authors](#authors)
- [Contributing](#contributing)
- [License](#license)

# What is PS Lab
PS Lab is a powerful Salesforce application designed to help Salesforce Administrators, Developers, and Architects visualize, analyze, and audit their org's permission structure. It transforms the complexity of Permission Sets and Permission Set Groups into an intuitive, interactive, and searchable hierarchy.

Managing permissions in a Salesforce org can be challenging. It's often difficult to answer simple questions like "Who has access to this Apex Class?" or "Which Permission Sets are giving access to certain objects and fields?". PS Lab provides the tools to answer these questions quickly and accurately.

# Key Features
* **Interactive Hierarchy Visualization**: Utilizes D3.js to render a dynamic, expandable tree diagram of all Permission Set Groups and standalone Permission Sets in your org.
* **Powerful Permission Detection**: Search for specific permissions, such as Object/Field access, Apex Class access, Custom Permissions, etc..., and instantly see which Permission Sets and Permission Set Groups grant them.
* **User Specific Analysis**: View the permission hierarchy as it is assigned to a specific user, making it easy to troubleshoot and audit individual access levels.
* **CSV Export**: Export any Permission Set’s configuration to a CSV file for offline analysis and documentation.

# What is not supported (Yet)
The following features are not currently available, but may be added in future versions:

* Analysis and CSV export for External Client App access.
* Support for Muting Permission Sets within Permission Set Groups.
* Analysis of metadata within managed packages.
* CSV export for Permission Set Groups.

# Pre-Installation Setup Guide
Before installing PSLab, you’ll need to set up a secure authentication channel so the app can call the Salesforce Tooling API on your behalf.
Please follow these **five steps** carefully

## Step 1: Create an External Client App

1. Navigate to Setup. In the Quick Find box, type "App Manager" and select **App Manager**.
2. In the top-right corner, click **New External Client App**.
3. Fill in the Basic Information:
   * **External Client App Name**: Tooling API Access (or a name of your choice).
   * **API Name**: This will auto-populate.
   * **Contact Email**: Enter your email address.
   * **Distribution State**: Local.
4. Scroll down to the **API (Enable OAuth Settings)** section, 
   * Mark **Enable OAuth** as checked.
   * **Callback URL**: Enter https://login.salesforce.com (This will be changed later)
   * **OAuth Scopes**: Select **Full Access (full)** & **Perform requests at any time (refresh_token, offline_access)**
5. Leave all other settings as their default values. Click **Create**.
6. Once created, click on the **Settings** tab, and open the **OAuth Settings** section, then click on **Consumer Key and Secret**.
   * **_Important_**: Copy both the Consumer Key and Consumer Secret into a temporary text file. You will need them in the next step.

## Step 2: Create an Authentication Provider

1. Navigate to Setup. In the Quick Find box, type "Auth. Providers" and select **Auth. Providers**.
2. Click New.
3. For the Provider Type, select **Salesforce**.
4. Fill in the details:
   * **Name**: Salesforce Tooling API
   * **URL Suffix**: 
   * **Consumer Key**: Paste the Consumer Key you copied from the External Client App.
   * **Consumer Secret**: Paste the Consumer Secret you copied from the External Client App.
   * **Default Scopes**: refresh_token full
5. Leave everything else as is, and save your changes.
6. Copy the value of the **Callback URL**.

## Step 3: Update the Callback URL in the External Client App
1. Navigate to Setup. In the Quick Find box, type "External Client App Manager" and select **External Client App Manager**.
2. Click *Edit Settings*.
3. Scroll to the **OAuth Settings** section.
4. Update the **Callback URL** with the copied callback url from **Step 2.6**.
5. Click Save.

## Step 4: Create an External Credentials

1. Navigate to Setup. In the Quick Find box, type "Named Credentials" and select **Named Credentials**.
2. Go to the **External Credentials** tab, and click **New**.
3. Fill in the details:
    * **Label**: Tooling API External Credentials
    * **Name**: Tooling_API_External_Credentials
    * **Authentication Protocol**: OAuth 2.0.
    * **Authentication Flow Type**: Browser flow
    * **Scope**: refresh_token full
    * **Identity Provider**: Select the Auth Provider you have created in [Step 2](#step-2-create-an-authentication-provider)
4. Click Save.
5. Scroll down to the **Principals** section, and click **New**.
6. Fill in the details:
   * **Parameter Name**: Tooling API Named Principal
   * **Identity Type**: Named Principal
7. Click Save
8. In the **Actions menu**, Click **Authenticate**, then follow the steps (They must be straight forward)
9. Verify that the **Authentication Status** is **Configured**

## Step 5: Create a Named Credential
The Named Credential is the final piece that your application will use to make secure, authenticated API calls. 

1. Navigate to Setup. In the Quick Find box, type "Named Credentials" and select **Named Credentials**.
2. Click the **New** button to create a new Named Credential.
3. Fill in the details:
   * **Label**: Tooling API Credentials
   * **Name**: Tooling_API_Credentials
     * **_CRITICAL_**: This name must be exactly **Tooling_API_Credentials** for the package to work correctly.
   * **URL**: Enter your org's domain URL. It should look like https://yourdomain.my.salesforce.com. You can copy this from your browser's address bar.
   * **Enabled for Callouts**: Toggled On
   * **External Credential**: Choose the External Credential created in [Step 4](#step-4-create-a-external-credentials)
   * Select the checkboxes for **Generate Authorization Header** and **Allow Formulas in HTTP Body**
   * Click Save

Setup is now complete! You can proceed with installing the package.

# Installation
Deploy via the deploy button

<a href="https://githubsfdeploy.herokuapp.com?owner=OumArbani&repo=PSLab">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

Alternatively, you can clone this repository and deploy using SFDX or your preferred deployment tool.

# Post-Installation Setup Guide

Once the deployment is done, follow these steps:
1. Navigate to Setup. In the Quick Find box, type "Permission Sets" and select **Permission Sets**.
2. Look for the **PS Lab User** permission set, and click on it.
3. Go to the **External Credential Principal Access**, then click **Edit**.
4. Select the **External Credential Principal Name** created in the [Pre-Installation Setup Guide](#pre-installation-setup-guide), and add it to the Enabled External Credential Principals list.
5. Click Save

And Voilà! You are all set to use PS Lab.


# Walkthrough

Here’s how PS Lab works in action:
1. **Explore the Permission Hierarchy**  
   Open PSLab from the App Launcher. You’ll see an interactive tree of all Permission Set Groups and Permission Sets in your org.
   ![Hierarchy Screenshot](resources/Hierarchy-Screenshot.gif)


2. **Search for Specific Permissions**  
   Use the search section to find access to objects, fields, Apex classes, or custom permissions.  
   PS Lab highlights where the permission is granted, whether in a Permission Set or a Permission Set Group.

   You can also narrow your search by selecting specific Permission Sets or Permission Set Groups to focus the analysis.
   ![Search Screenshot](resources/Search-Screenshot.gif)


3. **Analyze User Access**  
   Select a user to view their effective permission structure, including inherited access via Permission Set Groups.
   ![User Analysis Screenshot](resources/User-Analysis-Screenshot.gif)


4. **Export for Documentation**  
      Export any Permission Set to CSV for offline review or compliance audits.
   ![CSV Export Screenshot](resources/CSV-Export-Screenshot.gif)

# Authors
* Oumaima ARBANI - PS Lab Solution Designer & Developer

# Contributing
The strength of the Trailblazer community comes from everyone sharing their knowledge and experiences. I see this feature as a way to spark ideas and learn from one another. Your input, in any form, is always valued.
Feel free to open an issue or submit a pull request!
Please check [CONTRIBUTING.md](/CONTRIBUTING.md) for PS Lab contribution principles.

# License
This project license is MIT - please check the [LICENSE.md](/LICENSE) file for details.

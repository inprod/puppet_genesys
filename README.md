# What is InProd
InProd is a configuration management solution specifically
designed for the contact centre industry to reduce the risks and
costs associated with managing large Genesys powered contact centres.

InProd moves beyond just configuration auditing, it takes the headache out of managing multiple complex Genesys environments. InProd solves the common issues faced by large Genesys deployments. InProd enables the reuse of previous changes and drastically speeds up promoting changes from development to staging and into production.

# Puppet module
This project is a Puppet module for performing configuration changes within Genesys PureEngage.

The InProd Change set API is called by this module to perform the changes.

# Requirements
* Requires Puppet 4+

# Install
Clone this repo into a local folder on the puppet master.
`git clone https://github.com/inprod/puppet_genesys`

To build the module from the source code run
`puppet module build`

A folder will be created with the name of `pkg` to install package. To install the module run
`puppet module install /opt/inprod-puppet/inprod/pkg/inprod-changeset-1.0.0.tar.gz`

# TODO
* Validation errors are ignored
* Run errors are ignored
* Test cases to be added
* Code clean up

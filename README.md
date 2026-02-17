![Tests](https://github.com/inprod/puppet_genesys/actions/workflows/test.yml/badge.svg)
![License](https://img.shields.io/badge/license-Apache--2.0-blue)
![Puppet](https://img.shields.io/badge/puppet-7%20%7C%208-blue)
![Ruby](https://img.shields.io/badge/ruby-3.1%20%7C%203.2-blue)
![Version](https://img.shields.io/badge/module-2.0.0-green)

# InProd Puppet Module for Genesys Cloud

This module provides a Puppet resource type for managing Genesys Cloud configuration through [InProd](https://www.inprod.io) changesets. It can apply configuration changes across all object types within Genesys Cloud and is not limited in scope like the Genesys Cloud CLI tool 'Archy'.

Designed for use within CI/CD pipelines, this module enables Genesys Cloud configuration to be stored in version control and deployed across multiple Genesys Cloud environments using orchestration tools such as Jenkins, GitHub Actions, or similar platforms. All operations run as background tasks with automatic polling for completion.

# Requirements
* Requires Puppet 7+ or Puppet 8
* Ruby 2.7+ (Ruby 3.2 recommended for Puppet 8)

# Install

## Using PDK (recommended)
```
pdk build
puppet module install inprod/pkg/inprod-changeset-2.0.0.tar.gz
```

## Manual build
Clone this repo into a local folder on the puppet master.
```
git clone https://github.com/inprod/puppet_genesys
```

To build the module from the source code run
```
cd inprod
puppet module build
```

A folder will be created with the name of `pkg` to install package. To install the module run
```
puppet module install pkg/inprod-changeset-2.0.0.tar.gz
```

# Development

Install dependencies:
```
cd inprod
bundle install
```

If using Puppet 7 instead of Puppet 8, set the `PUPPET_GEM_VERSION` environment variable before running `bundle install`:
```
PUPPET_GEM_VERSION='~> 7.0' bundle install
```

Run tests:
```
bundle exec rake spec
```

Run lint:
```
bundle exec rake lint
bundle exec rake metadata_lint
```

# Authentication

This module uses API key authentication. Include your InProd API key using the `apikey` parameter:

```
Authorization: Api-Key <your-api-key>
```

Use Hiera or Puppet lookup to manage API keys securely rather than hardcoding them in manifests.

# Usage

This module provides a `changeset` resource type that lets you execute and validate InProd changesets against your Genesys environment. You can run the examples from the command line using `puppet apply`.

Example manifest files are provided in the [examples/](inprod/examples/) folder. Before running any example, edit the `.pp` file and replace the placeholder values (`apihost`, `apikey`, `path`, `environment`) with your own.

## Running a manifest

From the root of this repository, run any example using `puppet apply` with `--modulepath=.` so Puppet can find the `inprod` module:

```bash
puppet apply --modulepath=. inprod/examples/execute_json.pp
```

The `--modulepath=.` flag tells Puppet to look in the current directory for modules. This is required unless you have installed the module into Puppet's default module path (see [Install](#install)).

To see detailed output of what Puppet is doing, add `--verbose` or `--debug`:

```bash
puppet apply --modulepath=. --verbose inprod/examples/execute_json.pp
```

## Examples

### Execute a changeset from a JSON file

See [examples/execute_json.pp](inprod/examples/execute_json.pp). This executes a changeset defined in a JSON file (such as [examples/datatable.json](inprod/examples/datatable.json)):

```puppet
changeset { 'Execute datatable from JSON':
  ensure      => present,
  action      => 'executejson',
  path        => '/path/to/datatable.json',
  apihost     => 'https://your-company.inprod.io',
  apikey      => 'a1b2c3d4e5f6...your-api-key',
  environment => 'dev',
}
```

Run it:

```bash
puppet apply --modulepath=. inprod/examples/execute_json.pp
```

### Execute a changeset from a YAML file

See [examples/execute_yaml.pp](inprod/examples/execute_yaml.pp). Same as above but uses a YAML payload (such as [examples/datatable.yaml](inprod/examples/datatable.yaml)):

```puppet
changeset { 'Execute datatable from YAML':
  ensure      => present,
  action      => 'executeyaml',
  path        => '/path/to/datatable.yaml',
  apihost     => 'https://your-company.inprod.io',
  apikey      => 'a1b2c3d4e5f6...your-api-key',
  environment => 'dev',
}
```

Run it:

```bash
puppet apply --modulepath=. inprod/examples/execute_yaml.pp
```

### Validate a changeset from a JSON file

See [examples/validate_json.pp](inprod/examples/validate_json.pp). This validates a changeset without executing it, useful for dry-run checks before applying changes:

```puppet
changeset { 'Validate datatable from JSON':
  ensure      => present,
  action      => 'validatejson',
  path        => '/path/to/datatable.json',
  apihost     => 'https://your-company.inprod.io',
  apikey      => 'a1b2c3d4e5f6...your-api-key',
  environment => 'dev',
}
```

Run it:

```bash
puppet apply --modulepath=. inprod/examples/validate_json.pp
```

### Validate a changeset from a YAML file

See [examples/validate_yaml.pp](inprod/examples/validate_yaml.pp):

```puppet
changeset { 'Validate datatable from YAML':
  ensure      => present,
  action      => 'validateyaml',
  path        => '/path/to/datatable.yaml',
  apihost     => 'https://your-company.inprod.io',
  apikey      => 'a1b2c3d4e5f6...your-api-key',
  environment => 'dev',
}
```

Run it:

```bash
puppet apply --modulepath=. inprod/examples/validate_yaml.pp
```

### Execute a changeset by ID

If you have a changeset already saved in InProd, you can execute it directly by its numeric ID instead of providing a file:

```puppet
changeset { 'Execute changeset 124':
  ensure      => present,
  action      => 'execute',
  changesetid => '124',
  apihost     => 'https://your-company.inprod.io',
  apikey      => 'a1b2c3d4e5f6...your-api-key',
}
```

Save this to a file (e.g. `run_changeset.pp`) and run it:

```bash
puppet apply run_changeset.pp
```

### Custom polling settings

For long-running changesets, you can increase the timeout and polling interval:

```puppet
changeset { 'Long-running execution':
  ensure        => present,
  action        => 'execute',
  changesetid   => '124',
  apihost       => 'https://your-company.inprod.io',
  apikey        => 'a1b2c3d4e5f6...your-api-key',
  timeout       => 600,
  poll_interval => 10,
}
```

The `environment` parameter accepts either an environment ID (integer) or name (case insensitive). This overrides the environment defined in the JSON/YAML payload, making it useful for CI/CD workflows where the same changeset is promoted through environments.

# Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `action` | String | Yes | - | Action to perform: `execute`, `validate`, `executejson`, `executeyaml`, `validatejson`, or `validateyaml` |
| `apihost` | String | Yes | - | InProd API host URL (e.g. `https://your-company.inprod.io`) |
| `apikey` | String | Yes | - | API key for authentication (sensitive) |
| `changesetid` | String | No | - | Changeset ID (required for `execute` and `validate`) |
| `path` | String | No | - | Path to JSON or YAML file (required for file-based actions) |
| `environment` | String | No | - | Target environment ID or name override |
| `timeout` | Integer | No | 300 | Max seconds to wait for task completion |
| `poll_interval` | Integer | No | 5 | Seconds between polling requests |

# Async Task Polling

All changeset operations run as background tasks. When the API is called, it returns a `task_id`. The module then polls the task status endpoint until the task reaches a terminal state:

| Status | Behaviour |
|--------|-----------|
| `PENDING` | Task queued, continue polling |
| `STARTED` | Task running, continue polling |
| `SUCCESS` | Task completed, check result |
| `FAILURE` | Task failed, raise error |
| `REVOKED` | Task cancelled, raise error |

If the task does not complete within the `timeout` period, the module raises an error.

# TODO
* Add acceptance tests

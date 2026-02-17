changeset { 'Validate datatable from YAML':
  ensure      => present,
  action      => 'validateyaml',
  path        => '/path/to/datatable.yaml',
  apihost     => 'https://your-company.inprod.io',
  apikey      => 'a1b2c3d4e5f6...your-api-key',
  environment => 'dev',
}

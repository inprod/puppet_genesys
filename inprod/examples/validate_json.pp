changeset { 'Validate datatable from JSON':
  ensure      => present,
  action      => 'validatejson',
  path        => '/path/to/datatable.json',
  apihost     => 'https://your-company.inprod.io',
  apikey      => 'a1b2c3d4e5f6...your-api-key',
  environment => 'dev',
}

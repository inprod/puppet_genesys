changeset { 'Execute datatable from JSON':
  ensure      => present,
  action      => 'executejson',
  path        => 'inprod/examples/datatable.json',
  apihost     => 'http://192.168.0.128:8080',
  apikey      => '8e2213475246c44411a8f8c5455539e4d3cabebe47178baaeba8d95d9dc15f921651d20d8ce00fb120f00610fe461940',
  environment => 'dev',
}


changeset { 'validate datatable from JSON':
  ensure      => present,
  action      => 'validatejson',
  path        => 'inprod/examples/datatable.json',
  apihost     => 'http://192.168.0.128:8080',
  apikey      => '8e2213475246c44411a8f8c5455539e4d3cabebe47178baaeba8d95d9dc15f921651d20d8ce00fb120f00610fe461940',
  environment => '1',
}

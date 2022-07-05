control 'postgres-installed' do
  impact 'critical'
  title 'Postgres: Installed'
  desc 'Postgres Binaries are installed'

  describe package('postgresql-14') do
    it { should be_installed }
  end
end

control 'postgres-running' do
  impact 'critical'
  title 'Postgres: Running'
  desc 'Postgres service is running'

  describe processes('postgres') do
    it { should be_running }
  end
end

control 'postgres-user' do
  impact 'critical'
  title 'Postgres: User Created'
  desc 'Postgres default user has been created'

  describe postgres_session('postgres', 'mysecretpassword', 'localhost', 5432).query('SELECT usename FROM pg_catalog.pg_user;') do
    its('output') { should include 'postgres' }
  end
end

control 'postgres-db' do
  impact 'critical'
  title 'Postgres: Database Created'
  desc 'Postgres default database has been created'

  describe postgres_session('postgres', 'mysecretpassword', 'localhost', 5432).query('SELECT datname FROM pg_database;') do
    its('output') { should include 'db_test' }
  end
end

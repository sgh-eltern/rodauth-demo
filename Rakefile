require 'sequel'

namespace :db do
  desc "Setup database"
  task :setup do
    sh 'psql -U postgres -c "CREATE USER rodauth_test PASSWORD \'rodauth_test\'"'
    sh 'psql -U postgres -c "CREATE USER rodauth_test_password PASSWORD \'rodauth_test\'"'
    sh 'createdb -U postgres -O rodauth_test rodauth_test'
    sh 'psql -U postgres -c "CREATE EXTENSION citext" rodauth_test'

    $: << 'lib'
    require 'sequel'
    Sequel.extension :migration
    Sequel.postgres(:user=>'rodauth_test', :password=>'rodauth_test') do |db|
      Sequel::Migrator.run(db, 'db/migrations')
    end
  end

  desc "Teardown database"
  task :teardown do
    sh 'dropdb -U postgres rodauth_test'
    sh 'dropuser -U postgres rodauth_test_password'
    sh 'dropuser -U postgres rodauth_test'
  end
end

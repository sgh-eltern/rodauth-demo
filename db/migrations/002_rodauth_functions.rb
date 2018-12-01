require 'rodauth/migrations'

Sequel.migration do
  up do
    create_table(:account_password_hashes) do
      foreign_key :id, :accounts, :primary_key=>true, :type=>:Bignum
      String :password_hash, :null=>false
    end

    Rodauth.create_database_authentication_functions(self)
    user = get(Sequel.lit('current_user')).sub(/_password\z/, '')
    run "REVOKE ALL ON account_password_hashes FROM public"
    run "REVOKE ALL ON FUNCTION rodauth_get_salt(int8) FROM public"
    run "REVOKE ALL ON FUNCTION rodauth_valid_password_hash(int8, text) FROM public"
    run "GRANT INSERT, UPDATE, DELETE ON account_password_hashes TO #{user}"
    run "GRANT SELECT(id) ON account_password_hashes TO #{user}"
    run "GRANT EXECUTE ON FUNCTION rodauth_get_salt(int8) TO #{user}"
    run "GRANT EXECUTE ON FUNCTION rodauth_valid_password_hash(int8, text) TO #{user}"
  end

  down do
    Rodauth.drop_database_authentication_functions(self)
    drop_table(:account_password_hashes)
  end
end

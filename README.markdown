# Rodauth Demo Site

forked from https://github.com/jeremyevans/rodauth/tree/master/demo-site

# Development

1. Export the database URL:

   ```sh
   $ export DB=postgres://rodauth_test:rodauth_test@localhost/rodauth_test
   ```

1. (Re-)Create the database tables:

   ```sh
   $ bundle exec rake db:teardown db:setup
   ```

1. Reload the app whenever a file was changed:

   ```sh
   $ rerun -d . "bundle exec rackup"
   ```

# Deployment

* Create the database
* Migrate the database
* Set the `DB` and `RODAUTH_SESSION_SECRET` variables
* Start the app

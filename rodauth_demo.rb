require 'roda'
require 'sequel/core'
require 'mail'
require 'securerandom'

module RodauthDemo
  class App < Roda
    DB = Sequel.connect(ENV.delete('DB'))
    DB.extension :date_arithmetic
    DB.freeze

    ::Mail.defaults do
      delivery_method :test
    end

    opts[:root] = File.dirname(__FILE__)

    MAILS = {}
    MUTEX = Mutex.new
    TITLES = Hash.new{|h, k| h[k] = "TODO Translate '#{k}'" }.merge(
      'Login' => 'Anmelden',
      'Logout' => 'Abmelden',
      'Create Account' => 'Neues Konto anlegen',
      'Close Account' => 'Konto löschen',
    )

    plugin :render, :escape=>true
    plugin :request_aref, :raise
    plugin :hooks
    plugin :flash
    plugin :common_logger

    secret = ENV.delete('RODAUTH_SESSION_SECRET') || SecureRandom.random_bytes(64)
    plugin :sessions, :secret=>secret, :key=>'rodauth-demo.session'

    plugin :rodauth, :csrf => :route_csrf do
      db DB
      enable :email_auth, :login, :logout, :create_account, :close_account
      title_instance_variable :@page_title
      set_title do |title|
        scope.instance_variable_set(title_instance_variable, TITLES[title])
      end

      email_from 'Elternverteiler <verteiler@eltern-sgh.de>'
      email_auth_skip_resend_email_within 3 # TODO This should be larger unless in dev
      email_auth_email_recently_sent_error_flash 'TODO: The flash error to show if not sending an email auth email because another was sent recently.'
      email_auth_email_sent_notice_flash 'TODO: The flash notice to show after an email auth email has been sent.'
      email_auth_email_subject 'Ihr Link zum Anmelden beim SGH Elternverteiler'
      email_auth_error_flash 'TODO: The flash error to show if unable to login using email authentication.'
      email_auth_request_button 'TODO: The text to use for the email auth request button.'
      email_auth_request_error_flash 'TODO: The flash error to show if not able to send an email auth email.'
      no_matching_email_auth_key_message 'TODO: The flash error message to show if attempting to access the email auth form with an invalid key.'
      email_auth_email_body { ERB.new(File.read 'views/auth_email.erb').result(binding) }
      after_email_auth_request do
        warn "after_email_auth_request"
      end

      create_account_button 'Anlegen'
      create_account_link '<p><a href="/create-account">Neues Konto anlegen</a></p>'
      create_account_error_flash 'Ihr Konto konnte nicht angelegt werden. Wir bitten um Entschuldigung.'
      create_account_notice_flash 'Ihr Konto wurde angelegt. Herzlich willkommen!'
      create_account_set_password? false

      require_login_error_flash 'Diese Seite ist nur mit Anmeldung zugänglich.'
      login_button 'Anmelden'
      login_label 'eMail-Adresse'
      login_error_flash 'Die Anmeldung ist fehlgeschlagen.'
      login_notice_flash 'Ihre Anmeldung war erfolgreich.'
      login_does_not_meet_requirements_message 'Diese eMail-Adresse ist hier nicht gültig.'
      login_minimum_length 'a@x.yz'.size # shortest email address
      login_too_long_message 'Diese eMail-Adresse ist zu lang.'
      login_too_short_message 'Diese eMail-Adresse ist zu kurz.'
      require_login_confirmation? false
      no_matching_login_message 'Dieses Konto existiert nicht.'

      logout_button 'Abmelden'
      logout_notice_flash 'Sie wurden abgemeldet.'

      close_account_requires_password? false
      close_account_button 'Schließen'
      close_account_notice_flash 'Ihr Konto wurde geschlossen.'
      delete_account_on_close? true

      logout_redirect '/'
    end

    def last_mail_sent
      MUTEX.synchronize{MAILS.delete(rodauth.session_value)}
    end

    after do
      Mail::TestMailer.deliveries.each do |mail|
        MUTEX.synchronize{MAILS[rodauth.session_value] = mail}
      end
      Mail::TestMailer.deliveries.clear
    end

    route do |r|
      # TODO check_csrf!
      r.rodauth

      r.root do
        @page_title = 'Herzlich Willkommen'
        view 'index'
      end

      r.on 'erziehungsberechtigte' do
        rodauth.require_authentication
        @page_title = 'Erziehungsberechtigte'
        view 'erziehungsberechtigte'
      end
    end

    freeze
  end
end

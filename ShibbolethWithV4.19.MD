Warning: only https works with shibboleth.

/leihs/legacy/config/settings.yml
Do not modify. Just here as a warning.
```
#Shibboleth_config does not exist in settings DB table
#Do not activate this line, or leihs-legacy service will not start
#shibboleth_config: shibboleth.yml
```

/leihs/legacy/config/shibboleth.yml
```
production:
  #ShibUseHeaders: read user attributes from http header instead of environment variables, because 
  #proxying to Puma/leihs-legacy makes it impossible to read request environment variables from Apache
  ShibUseHeaders: true
  #when ShibUseHeaders = false
  #unique_id_field: REMOTE_USER
    #when ShibUseHeaders = true
  #unique_id_field: HTTP_REMOTE_USER
  unique_id_field: HTTP_REMOTE_USER
  firstname_field: HTTP_GIVENNAME
  lastname_field: HTTP_SN
  mail_field: HTTP_MAIL
  admin_uids:
    - v15053
    - v15067
```

/leihs/legacy/app/controllers/authenticator/shibboleth_authentication_controller.rb
```ruby
# In order to use this Shibboleth authenticator, you must put the entire
# leihs instance behind a shibboleth "secure" location:
#
# <Location />
#    AuthType shibboleth
#    ShibRequireSession On
#    require valid-user
#  </Location>
#
# You must also have a working service provider (SP) for this instance.

class Authenticator::ShibbolethAuthenticationController \
  < Authenticator::AuthenticatorController

  before_action :load_config
  layout 'layouts/manage/general'
  
  logger = Rails.logger
 
  def load_config
    begin
      if (defined?(Setting::SHIBBOLETH_CONFIG) \
          and not Setting::SHIBBOLETH_CONFIG.blank?)
        shibboleth_config = YAML::load_file(Setting::SHIBBOLETH_CONFIG)
      else
        shibboleth_config = YAML::load_file(File.join(Rails.root,
                                                      'config',
                                                      'shibboleth.yml'))
      end

      if shibboleth_config[Rails.env].nil?
        raise('The configuration section for the environment ' \
              "'#{Rails.env}' is missing in your shibboleth config file.")
      else
        @config = shibboleth_config[Rails.env]
        validate_config
      end

      if @config['admin_uids']
        @super_users = @config['admin_uids']
      end
    rescue Exception => e
      raise "Shibboleth configuration file is invalid or not present: #{e}"
    end
  end

  def validate_config
    required_fields = %w(unique_id_field firstname_field lastname_field mail_field)
    required_fields.map do |field|
      if !@config[field] or @config[field].blank?
        raise('The Shibboleth configuration file ' \
              "is missing the '#{field}' setting.")
      end
    end
  end

  def login_form_path
    '/authenticator/shibboleth/login'
  end

  def login
    super
    # This point should only be reached after a successful login from Shibboleth.
    # Shibboleth handles all error management, so we don't need to worry about any
    # of that.
    
    #todo:
    #how do I switch to debug level "debug"?
    #request.env.each do |item|
    #    logger.error("request env name: #{item[0]}, value: #{item[1]}")
    #end
    
    #request.headers.each do |item|
    #    logger.error("request header name: #{item[0]}, value: #{item[1]}")
    #end  
    
    if @config['ShibUseHeaders']
        uid = request.headers[@config['unique_id_field']]
    else
        uid = request.env[@config['unique_id_field']]
    end
     
    #debug
    #logger.debug("Shibboleth Identity Provider env: #{request.env["Shib-Identity-Provider"]}")
    #logger.debug("Shibboleth Identity Provider header: #{request.headers[:HTTP_SHIB_IDENTITY_PROVIDER]}")
    
    if uid.blank?
      logger.error('Shibboleth login: User ID was blank! Redirecting to root path')
      raise('Shibboleth login: User ID was blank! Redirecting to root path')
      redirect_to root_path
    else
      self.current_user = create_or_update_user
      redirect_to root_path
    end
  end

  def create_or_update_user
    # request.env after Shibboleth authentication looks like this:
    # (Leihs v4.19.0: only true if no proxy is used, which is always the case with Ansible deployment.
    #  Otherwise env does not get populated with values. User request.headers instead.)
    #    "uid"=>"e10262@zhdk.ch",
    #    "homeOrganizationType"=>"uas",
    #    "givenName"=>"Ramon",
    #    "Shib-AuthnContext-Class"=>
    #    "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport",
    #    "Shib-Identity-Provider"=>"https://aai-logon.zhdk.ch/idp/shibboleth",
    #    "Shib-InetOrgPerson-givenName"=>"Ramon",
    #    "Shib-Authentication-Method"=>
    #    "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport",
    #    "mail"=>"ramon.cahenzli@zhdk.ch",
    #    "Shib-SwissEP-HomeOrganization"=>"zhdk.ch",
    #    "Shib-Application-ID"=>"leihs2shib",
    #    "Shib-Person-surname"=>"Cahenzli",
    #    "Shib-EP-Affiliation"=>"faculty;staff;member",
    #    "Shib-Authentication-Instant"=>"2010-09-28T07:03:59.738Z",
    #    "Shib-SwissEP-UniqueID"=>"e10262@zhdk.ch",
    #    "Shib-SwissEP-HomeOrganizationType"=>"uas",
    #    "Shib-InetOrgPerson-mail"=>"ramon.cahenzli@zhdk.ch",
    #    "Shib-Session-ID"=>"_22d5e2f708f663eae29d2afeae08dfff",
    #    "surname"=>"Cahenzli", "homeOrganization"=>"zhdk.ch",
    #    "affiliation"=>"faculty;staff;member"
    #
   

    if @config['ShibUseHeaders']
      uid = request.headers[@config['unique_id_field']]
      email = request.headers[@config['mail_field']]
      user = \
        User.where(unique_id: uid).first \
        || User.where(email: email).first \
        || User.new
      user.unique_id = uid
      user.login = uid
      user.email = email
      user.firstname = "#{request.headers[@config['firstname_field']]}"
      user.lastname = "#{request.headers[@config['lastname_field']]}"
    else
      uid = request.headers[@config['unique_id_field']]
      email = request.headers[@config['mail_field']]
      user = \
        User.where(unique_id: uid).first \
        || User.where(email: email).first \
        || User.new
      user.unique_id = uid
      user.login = uid
      user.email = email
      user.firstname = "#{request.headers[@config['firstname_field']]}"
      user.lastname = "#{request.headers[@config['lastname_field']]}"
    end
    user.authentication_system = \
      AuthenticationSystem.where(class_name: 'ShibbolethAuthentication').first
    user.save
    unless user.errors.full_messages.blank?
      logger = Rails.logger
      logger.error user.errors.full_messages
    end

    if @super_users.include?(user.unique_id)
      user.access_rights.create(role: :admin, inventory_pool: nil)
    end
    user
  end

end
```


/etc/apache2/leihs/1_https.conf
```
# Managed with ansible


#Franzkoch
RemoteIPHeader X-Forwarded-For
RemoteIPInternalProxy dmz-gwext01.mhtnet.example.com
#/Franzkoch

<VirtualHost *:443>
    SSLEngine on
    
    #SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    #SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
    
    #Franzkoch
    SSLCertificateFile /etc/ssl/certs/mht/mhtcert.pem
    SSLCertificateKeyFile /etc/ssl/private/mht/mhtcert.key
    SSLCACertificateFile /etc/ssl/certs/mht/mhtchain.pem
    
    #protect everything with shibboleth
    <Location / >
      #Use Headers to pass user attributes to Puma/leihs-legacy, because it has no access to 
      #the environment variables inside  Apache
      ShibUseHeaders On
      AuthType Shibboleth
      ShibRequestSetting requireSession true
      Require valid-user
    </Location>

    #According to Shib documentation
    #Shibboleth session hook
    <Location /Shibboleth.sso>
    SetHandler shib
    Require all granted
    #Exclude the Shibboleth session hook from mod_proxy redirect to leihs-legacy
    ProxyPass ! 
    </Location>

    # Metadata via entityID-URL shorthand
    Redirect seeother /shibboleth https://leihs.example.com/Shibboleth.sso/Metadata
    #Exclude from redirect to leihs-legacy
    ProxyPass /shibboleth ! 
    
    <Location /shibboleth-sp>
    Require all granted
    #Exclude from redirect to leihs-legacy
    ProxyPass !
    </Location>
    Alias /shibboleth-sp/main.css /usr/share/shibboleth/main.css
    #Alias /shibboleth-sp/logo.jpg /usr/share/shibboleth/mhtlogo.jpg
    #/Franzkoch

    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off

    SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
    SSLProtocol +TLSv1 +TLSv1.1 +TLSv1.2
    SSLHonorCipherOrder On
    # SSLSessionTickets Off
    # TODO reenalbe STS
    # Header always set Strict-Transport-Security "max-age=63072000; preload"
    # Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    # Requires Apache >= 2.4
    SSLCompression off
    # SSLUseStapling on
    # SSLStaplingCache "shmcb:logs/stapling-cache(150000)"


    Include /etc/apache2/leihs/shared.conf
    
    #Franzkoch
    #Change all URLs passed back to the client to be https. Because SSLProxyEngine is ON
    ProxyPassReverse / http://leihs.example.com/
    #/Franzkoch

    ###############################################################################
    ### logging ###################################################################
    ###############################################################################

    ErrorLog ${APACHE_LOG_DIR}/leihs_default_error.log
    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel info

    CustomLog ${APACHE_LOG_DIR}/leihs_default_access.log combined

</VirtualHost>
# vim: syntax=apache
 ```

Start a Rails console inside your Leihs Legacy directory:
You can find the value for leihs_legacy_ruby_version in ```/leihs/deploy/all.yml```.
```bash
cat /leihs/deploy/all.yml | grep 'leihs_legacy_ruby_version'
```
```bash
su leihs-legacy
cd /leihs/legacy
export PATH=$HOME/.rubies/ruby-**<leihs_legacy_ruby_version>**/bin:$PATH
RAILS_ENV=production bundle exec rails console
```

```bash
shib = AuthenticationSystem.find_or_initialize_by(class_name: 'ShibbolethAuthentication')
shib.name ||= 'Shibboleth Authentication'
shib.is_default = false
shib.is_active = true
shib.save

ldap = AuthenticationSystem.find_or_initialize_by(class_name: 'LdapAuthentication')
ldap.name ||= 'LDAP Authentication'
ldap.is_default = false
ldap.is_active = false
ldap.save
exit
systemctl restart leihs-legacy
```

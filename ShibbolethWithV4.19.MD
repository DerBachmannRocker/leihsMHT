Warning: only https works with shibboleth.

settings.yml
```
#Shibboleth_config does not exist in settings DB table
#Do activate this line, or leihs-legacy service will not start
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
    

    #from shibboleth_authentication_conroller.rb
    #<Location />
    #AuthType shibboleth
    #ShibRequireSession On
    #require valid-user
    #</Location>
    
    #lazy login / no security
    #<Location / >
    #    AuthType Shibboleth
    #    ShibRequestSetting requireSession false
    #    Require shibboleth
    #</Location>
    
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

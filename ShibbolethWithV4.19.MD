Warning: only https works with shibboleth.

settings.yml
```
#Shibboleth_config does not exist in settings DB table
#Do not comment in this line, or leihs-legacy service will not start
#shibboleth_config: shibboleth.yml
```


shibboleth.yml
```
production:
  unique_id_field: uid
  firstname_field: givenName
  lastname_field: sn
  mail_field: email
  admin_uids:
    - v15053
    - v15067
```

Start a Rails console inside your Leihs Legacy directory:
You can find the value for leihs_legacy_ruby_version in ```/leihs/deploy/all.yml```.
```bash
cat /leihs/deploy/all.yml | grep 'leihs_legacy_ruby_version'```
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
exit
```

verify you set the correct names for user attributes. Only users with all attributes set are able to log in.
example values that worked for me (email == mail!)
```yaml
production:
  unique_id_field: uid
  firstname_field: givenName
  lastname_field: sn
  mail_field: mail
  admin_uids:
    - v15053
    - v15067
 ```
    
 admin_uids: list of usernames that get admin privileges

Set all auth mechanisms to false, except Shibboleth
DB table ```authentication_systems```

/etc/apache2/leihs/shared.conf
```
<Location />
  AuthType shibboleth
  ShibRequireSession On
  require valid-user
</Location>
 
<Location /Shibboleth.sso>
  SetHandler shib
  Require all granted
</Location>
#Exclude the Shibboleth session hook from mod_proxy
ProxyPass /Shibboleth.sso ! 
 ```



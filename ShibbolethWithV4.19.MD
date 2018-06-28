Needed in settings.yml
shibboleth_config: shibboleth.yml

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

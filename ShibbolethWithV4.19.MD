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

/etc/shibboleth/shibboleth2.xml
```xml
<SPConfig xmlns="urn:mace:shibboleth:2.0:native:sp:config"
    xmlns:conf="urn:mace:shibboleth:2.0:native:sp:config"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"    
    xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
    logger="syslog.logger" clockSkew="180">

    <!-- The OutOfProcess section contains properties affecting the shibd daemon. -->
    <OutOfProcess logger="shibd.logger">
        <!--
        <Extensions>
            <Library path="odbc-store.so" fatal="true"/>
        </Extensions>
        -->
    </OutOfProcess>

    <!--
    The InProcess section contains settings affecting web server modules.
    Required for IIS, but can be removed when using other web servers.
    -->
    <!-- Franzkoch, Spoofing protection ON -->
    <!-- spoofKey is only configured here. Random value. --> 
    <InProcess logger="native.logger" checkSpoofing="true" spoofKey="xxxxxxxxxxxxxxxxx">
     
        <!-- <ISAPI normalizeRequest="true" safeHeaderNames="true"> -->
            <!--
            Maps IIS Instance ID values to the host scheme/name/port. The name is
            required so that the proper <Host> in the request map above is found without
            having to cover every possible DNS/IP combination the user might enter.
            -->
        <!--        <Site id="1" name="sp.example.org"/> -->
            <!--
            When the port and scheme are omitted, the HTTP request's port and scheme are used.
            If these are wrong because of virtualization, they can be explicitly set here to
            ensure proper redirect generation.
            -->
            <!--
            <Site id="42" name="virtual.example.org" scheme="https" port="443"/>
            -->
        <!-- </ISAPI> -->
    </InProcess>
    
    <!-- Only one listener can be defined, to connect in-process modules to shibd. -->
    <UnixListener address="shibd.sock"/>
    <!-- <TCPListener address="127.0.0.1" port="1600" acl="127.0.0.1"/> -->
    
    <!-- This set of components stores sessions and other persistent data in daemon memory. -->
    <StorageService type="Memory" id="mem" cleanupInterval="900"/>
    <SessionCache type="StorageService" StorageService="mem" cacheAssertions="false"
                  cacheAllowance="900" inprocTimeout="900" cleanupInterval="900"/>
    <ReplayCache StorageService="mem"/>
    <ArtifactMap artifactTTL="180"/>

    <!-- This set of components stores sessions and other persistent data in an ODBC database. -->
    <!--
    <StorageService type="ODBC" id="db" cleanupInterval="900">
        <ConnectionString>
        DRIVER=drivername;SERVER=dbserver;UID=shibboleth;PWD=password;DATABASE=shibboleth;APP=Shibboleth
        </ConnectionString>
    </StorageService>
    <SessionCache type="StorageService" StorageService="db" cacheAssertions="false"
                  cacheTimeout="3600" inprocTimeout="900" cleanupInterval="900"/>
    <ReplayCache StorageService="db"/>
    <ArtifactMap StorageService="db" artifactTTL="180"/>
    -->

    <!--
    To customize behavior for specific resources on Apache, and to link vhosts or
    resources to ApplicationOverride settings below, use web server options/commands.
    See https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPConfigurationElements for help.
    
    For examples with the RequestMap XML syntax instead, see the example-shibboleth2.xml
    file, and the https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPRequestMapHowTo topic.
    -->
    <RequestMapper type="Native">
        <RequestMap>
            <!--
            The example requires a session for documents in /secure on the containing host with http and
            https on the default ports. Note that the name and port in the <Host> elements MUST match
            Apache's ServerName and Port directives or the IIS Site name in the <ISAPI> element above.
            -->
            <!--
            <Host name="sp.example.org">
                <Path name="secure" authType="shibboleth" requireSession="true"/>
            </Host>
            -->
            <!-- Example of a second vhost mapped to a different applicationId. -->
            <!--
            <Host name="admin.example.org" applicationId="admin" authType="shibboleth" requireSession="true"/>
            -->
        </RequestMap>
    </RequestMapper>

    <!--
    The ApplicationDefaults element is where most of Shibboleth's SAML bits are defined.
    Resource requests are mapped by the RequestMapper to an applicationId that
    points into to this section (or to the defaults here).
    -->
    
    <!-- eppn = eduPersonPrincipalName -->
    <ApplicationDefaults entityID="https://leihs.example.com/shibboleth"
                         homeURL="https://leihs.example.com/Shibboleth.sso/Session"
                         metadataAttributePrefix="Meta-"
                         REMOTE_USER="uid"
                         signing="back"
                         requireTransportAuth="false"
                         sessionHook="/Shibboleth.sso/AttrChecker"
                         cipherSuites="ECDHE+AESGCM:ECDHE:!aNULL:!eNULL:!LOW:!EXPORT:!RC4:!SHA:!SSLv2">
        <!--
        Controls session lifetimes, address checks, cookie handling, and the protocol handlers.
        You MUST supply an effectively unique handlerURL value for each of your applications.
        The value defaults to /Shibboleth.sso, and should be a relative path, with the SP computing
        a relative value based on the virtual host. Using handlerSSL="true", the default, will force
        the protocol to be https. You should also set cookieProps to "https" for SSL-only sites.
        Note that while we default checkAddress to "false", this has a negative impact on the
        security of your site. Stealing sessions via cookie theft is much easier with this disabled.
        -->
        <Sessions lifetime="28800" timeout="3600" checkAddress="false"
            handlerURL="/Shibboleth.sso" consistentAddress="true" handlerSSL="true" cookieProps="https" relayState="ss:mem"
            exportLocation="http://localhost/Shibboleth.sso/GetAssertion" exportACL="127.0.0.1"
            idpHistory="false" idpHistoryDays="7">

            <!--
            The "stripped down" files use the shorthand syntax for configuring handlers.
            This uses the old "every handler specified directly" syntax. You can replace
            or supplement the new syntax following these examples.
            -->
          
		    <!--
            Configures SSO for a default IdP. To allow for >1 IdP, remove
            entityID property and adjust discoveryURL to point to discovery service.
            (Set discoveryProtocol to "WAYF" for legacy Shibboleth WAYF support.)
            You can also override entityID on /Login query string, or in RequestMap/htaccess.
            <SSO entityID="https://idp.example.org/idp/shibboleth"
                 discoveryProtocol="SAMLDS" discoveryURL="https://ds.example.org/DS/WAYF">
              SAML2 SAML1
            </SSO>
            -->
            
            <!-- Leihs: setting 'target' attribute should redirect the user automatically, skipping over the "login" page. This is optional-->
            <SSO entityID="https://idp.example.com/idp/shibboleth"
                 target="https://leihs.example.com/authenticator/shibboleth/login">
                SAML2 
            </SSO>
		  
		  
            <!--
            SessionInitiators handle session requests and relay them to a Discovery page,
            or to an IdP if possible. Automatic session setup will use the default or first
            element (or requireSessionWith can specify a specific id to use).
            -->

            <!-- Default directs to a specific IdP (favoring SAML 2 over Shib 1). -->
            <!--
			<SessionInitiator type="Chaining" Location="/Login" isDefault="true" id="Login"
                              entityID="https://idp.example.com/idp/shibboleth">
              
                <SessionInitiator type="SAML2" template="bindingTemplate.html"/>
                <SessionInitiator type="Shib1"/>
			-->
                <!--
                To allow for >1 IdP, remove entityID property from Chaining element and add
                *either* of the SAMLDS or WAYF handlers below:
                
                <SessionInitiator type="SAMLDS" URL="https://ds.example.org/DS/WAYF"/>
                <SessionInitiator type="WAYF" URL="https://wayf.example.org/WAYF"/>
                -->
            <!-- </SessionInitiator> -->
            
            <!--
            md:AssertionConsumerService locations handle specific SSO protocol bindings,
            such as SAML 2.0 POST or SAML 1.1 Artifact. The isDefault and index attributes
            are used when sessions are initiated to determine how to tell the IdP where and
            how to return the response.
            -->
            <md:AssertionConsumerService Location="/SAML2/POST" index="1"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"/>
            <md:AssertionConsumerService Location="/SAML2/POST-SimpleSign" index="2"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST-SimpleSign"/>
            <md:AssertionConsumerService Location="/SAML2/Artifact" index="3"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"/>
            <md:AssertionConsumerService Location="/SAML2/ECP" index="4"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:PAOS"/>
            <md:AssertionConsumerService Location="/SAML/POST" index="5"
                Binding="urn:oasis:names:tc:SAML:1.0:profiles:browser-post"/>
            <md:AssertionConsumerService Location="/SAML/Artifact" index="6"
                Binding="urn:oasis:names:tc:SAML:1.0:profiles:artifact-01"/>

            <!-- LogoutInitiators enable SP-initiated local or global/single logout of sessions. -->
            <LogoutInitiator type="Chaining" Location="/Logout">
                <LogoutInitiator type="SAML2" template="bindingTemplate.html" signing="true"/>
                <!-- <LogoutInitiator type="Local" signing="true"/> -->
            </LogoutInitiator>

            <!-- md:SingleLogoutService locations handle single logout (SLO) protocol messages. -->
            <md:SingleLogoutService Location="/SLO/SOAP"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"/>
            <md:SingleLogoutService Location="/SLO/Redirect" conf:template="bindingTemplate.html"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"/>
            <md:SingleLogoutService Location="/SLO/POST" conf:template="bindingTemplate.html"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"/>
            <md:SingleLogoutService Location="/SLO/Artifact" conf:template="bindingTemplate.html"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"/>

            <!-- md:ManageNameIDService locations handle NameID management (NIM) protocol messages. -->
            <md:ManageNameIDService Location="/NIM/SOAP"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"/>
            <md:ManageNameIDService Location="/NIM/Redirect" conf:template="bindingTemplate.html"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"/>
            <md:ManageNameIDService Location="/NIM/POST" conf:template="bindingTemplate.html"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"/>
            <md:ManageNameIDService Location="/NIM/Artifact" conf:template="bindingTemplate.html"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"/>

            <!--
            md:ArtifactResolutionService locations resolve artifacts issued when using the
            SAML 2.0 HTTP-Artifact binding on outgoing messages, generally uses SOAP.
            -->
            <md:ArtifactResolutionService Location="/Artifact/SOAP" index="1"
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"/>

            <!-- Extension service that generates "approximate" metadata based on SP configuration. -->
            <Handler type="MetadataGenerator" Location="/Metadata" signing="false"/>


            <!-- Status reporting service. -->
            <Handler type="Status" Location="/Status" acl="127.0.0.1 ::1"/>
			
            <!-- Session diagnostic service. -->
            <Handler type="Session" Location="/Session" showAttributeValues="true"/>

            <!-- JSON feed of discovery information. -->
            <Handler type="DiscoveryFeed" Location="/DiscoFeed"/>

            <!-- Checks for required attribute(s) before login completes. -->
            <!-- This should be activated as the last step, or else debugging during setup is more difficult -->
            <Handler type="AttributeChecker" Location="/AttrChecker" template="attrChecker.html" flushSession="true">
               <AND>
                 <!-- attribute-map.xml: id of attributes -->
                 <RuleRegex require="eppn" caseSensitive="false">^.+@example\.com$</RuleRegex>
               </AND>
            </Handler>

        </Sessions>

        <!--
        Allows overriding of error template information/filenames. You can
        also add attributes with values that can be plugged into the templates.
        -->
        <Errors supportContact="administrator@example.com"
            helpLocation="/about.html"
            styleSheet="/shibboleth-sp/main.css"/>
        
        <!--
        Uncomment and modify to tweak settings for specific IdPs or groups. Settings here
        generally match those allowed by the <ApplicationDefaults> element.
        -->
        <!--
        <RelyingParty Name="SpecialFederation" keyName="SpecialKey"/>
        -->

        <!-- Example of remotely supplied batch of signed metadata. -->
        <!--
        <MetadataProvider type="XML" validate="true"
	      uri="http://federation.org/federation-metadata.xml"
              backingFilePath="federation-metadata.xml" reloadInterval="7200">
            <MetadataFilter type="RequireValidUntil" maxValidityInterval="2419200"/>
            <MetadataFilter type="Signature" certificate="fedsigner.pem"/>
            <DiscoveryFilter type="Blacklist" matcher="EntityAttributes" trimTags="true" 
              attributeName="http://macedir.org/entity-category"
              attributeNameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"
              attributeValue="http://refeds.org/category/hide-from-discovery" />
          </MetadataProvider>
        -->
		
		<MetadataProvider type="Chaining">
            <MetadataProvider type="XML" validate="true"
                  uri="https://www.aai.dfn.de/fileadmin/metadata/dfn-aai-local-599-metadata.xml"
                  backingFilePath="DFN-AAI-Local-599-metadata.xml" 
                  reloadInterval="3600">
               <MetadataFilter type="Signature" certificate="/etc/ssl/certs/mht/dfn-aai.g2.pem" />
            </MetadataProvider>
        </MetadataProvider>

        <!-- Example of locally maintained metadata. -->
        <!--
        <MetadataProvider type="XML" validate="true" file="partner-metadata.xml"/>
        -->

        <!-- TrustEngines run in order to evaluate peer keys and certificates. -->
        <TrustEngine type="ExplicitKey"/>
        <!-- <TrustEngine type="PKIX"/> -->

        <!-- Map to extract attributes from SAML assertions. -->
        <AttributeExtractor type="XML" validate="true" reloadChanges="false" path="attribute-map.xml"/>

        <!-- Use a SAML query if no attributes are supplied during SSO. -->
        <AttributeResolver type="Query" subjectMatch="true"/>

        <!-- Default filtering policy for recognized attributes, lets other data pass. -->
        <AttributeFilter type="XML" validate="true" path="attribute-policy.xml"/>

        <!-- Simple file-based resolver for using a single keypair. -->
        <!-- <CredentialResolver type="File" key="sp-key.pem" certificate="sp-cert.pem"/> -->
		
		<!--
        Certificate/Private key pairs are read in sequence.
        Unless specificially defined only the first
        CredentialResolver is used for attribute requests.
        More information:
        https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPCredentialResolver
        -->
        <CredentialResolver type="Chaining">
             <!-- Active certificate -->
             <CredentialResolver type="File"
                                 key="/etc/ssl/private/mht/mhtcert.key"
                                 certificate="/etc/ssl/certs/mht/mhtcert.pem"/>
        </CredentialResolver>

        <!--
        The default settings can be overridden by creating ApplicationOverride elements (see
        the https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPApplicationOverride topic).
        Resource requests are mapped by web server commands, or the RequestMapper, to an
        applicationId setting.
        
        Example of a second application (for a second vhost) that has a different entityID.
        Resources on the vhost would map to an applicationId of "admin":
        -->
        <!--
        <ApplicationOverride id="admin" entityID="https://admin.example.org/shibboleth"/>
        -->
    </ApplicationDefaults>
    
    <!-- Policies that determine how to process and authenticate runtime messages. -->
    <SecurityPolicyProvider type="XML" validate="true" path="security-policy.xml"/>

    <!-- Low-level configuration about protocols and bindings available for use. -->
    <ProtocolProvider type="XML" validate="true" reloadChanges="false" path="protocols.xml"/>

</SPConfig>
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

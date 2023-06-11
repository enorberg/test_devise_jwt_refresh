# README - Test Devise Jwt Refresh 

Use devise and devise-jwt gems - see: 
  https://sdrmike.medium.com/rails-7-api-only-app-with-devise-and-jwt-for-authentication-1397211fb97c

{ ------ 
  For an alternate method that does NOT use the devise-jwt gem, see:
   https://dev.to/dhintz89/devise-and-jwt-in-rails-2mlj
 ----- }

Steps for setup:
  - Create an app:  rails new test_devise_jwt_refresh --api --skip-test
    (note: use default Sqlite3 db.)

  - Enable cors since front end will in general be on a different server
    uncomment  gem 'rack-cors' in Gemfile
    bundle install
    edit initializers/cors.rb  to
      un-comment code and set origins to "*".
      add to resource: expose: [:Authorization]

  - Add devise related gems to Gemfile
     gem 'devise'
     gem 'devise-jwt'
     gem 'jsonapi-serializer'
     ..and run   bundle install

  - Setup Devise
     rails g devise:install
     Edit config/initializers/devise.rb to have ... config.navigational_formats = []
     ...to leave port 3000 open for hypothetical front-end, switch puma & mail to 3001...
     Edit config/environments/development.rb  to include a mailer config ... uses port 3001
     Edit config/puma.rb    for the same port -- 3001
     Generate the devise user .... rails g devise User
     Create the db and run 1st migration ... rails db:create db:migrate
     Generate the devise controllers - sessions & registrations  ...
       rails g devise:controllers users -c sessions registrations
     Modify the new controllsers to respond to JSON:
      ./app/controllers/users/sessons_controller.rb 
      ./app/controllers/users/registrations_controller.rb 
     Override the devise default routes and add route aliases. (see config/routes.rb)
     Devise has default registration parmeters:
       email, password, password confirmation, remember me
     To add to these, edit  /app/controllers/application_controller.rb:
       ... add these: user_id, last_name, nick_name.
     Add these fields to db: 
       rails g migration AddUserIdLastNameNickNameToUser user_id:string last_name:string nick_name:string
       rails db:migrate

     Devise-JWT setup,
       -- Secret Key.  
         bundle exec rake secret   ==> gen key to terminal.
         EDITOR='nano --wait' rails credentials:edit  
          use nano or other editor that can accept 'wait', append the following:
            # Used as the base secret for Devise-JWT 
            devise_jwt_secret_key: (copy and paste the generated secret here)
            
       -- Configure JWT handeling for login/logout.
         Edit config/initializers/devise.rb  ...add to end config.jwt do ... to
            - specify the devise-jwt secret key
            - declare login & logout route
            - define JWT expiration period.  (e.g. 30 minutes in this example)
              NOTE: changed timeout to 60 minutes.:w

       -- Token revokation - use JTIMatcher.  (JWT Id : JTI in token must match JTI col in db)
         Add JTI column to Users model.
         rails g migration addJtiToUsers jti:string:index:unique
         ... edit migration file to have column null: false and index unique: true ...
         rails db:migrate
         Configure the User model accordingly:  edit /app/models/user.rb  to add...
            include Devise::JWT::RevocationStrategies::JTIMatcher
            devise ... :jwt_authenticatable, jwt_revocation_strategy: self

       -- User serializer
         Create with ... rails g serializer user user_id email last_name nick_name

     Add behavior for registration, login and logout.
       -- edit app/controllers/users/registrations_controller.rb
          ... add "respond_with() function ...

       -- edit app/controllers/users/sessions_controller.rb
          ... add "respond_with()" and "respond_to_on_destroy()" functions...

       -- Rails Sessions are not writtable in an API app.  Workaround by creating
          a fake session hash.  
          ... add app/controllers/concerns/rack_sessions_fix.rb file.
          ... include this concern in our sessions_controller.rb and 
              registrations_controller.rb before respond_to :json

Test initial setup with Postman:
  (see ./Test_with_Postman  for a .json file of exported tests)
  -- Add User.   Note: to set the Content-Type header, use the JSON drop down in Body.
     POST http://localhost:3001/signup
     { "user": { "nick_name": "Fred", "email": "ff2@gmail.com", "password": "fghijk" } }

  -- Log in. 
     POST http://localhost:3001/login
     { "user": { "email": "ff2@gmail.com", "password": "fghijk" } }
     ...return in Authorization Header.
     Bearer eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJjM2ZmZTY4Ni1mY2E0LTQwODUtOWVlNy1jN2ZjOWQwZjIwNjgiLCJzdWIiOiIyIiwic2NwIjoidXNlciIsImF1ZCI6bnVsbCwiaWF0IjoxNjgzODI2MDczLCJleHAiOjE2ODM4Mjc4NzN9.2rIZZgHnW7Gtvh_OnW03rA9nMsdESCdxS5wDZ8NFsKw

  -- Log out.  set Authorization header with token from login and send DELETE request
      ... Authorization  Bearer eyJh.....Kw
       Note: setting token - Take "Authorization" drop dwn - add hash value w/o the Bearer
     DELETE http://localhost:3001/logout

Issues:

  00. Expand Users and add UserRelayRegistrations:
     Add to Users table:
       rails g migration AddMissingFieldsToUsers first_name:string cell_number:string 
            pin:integer age_at_signup:integer date_of_signup:date admin_flg:boolean

     Add UserRelayRegistrations modle and db table
       rails g migration CreateUserRelayRegistrations user_id:string device_guid:string 
         device_description:string usage_count:integer
  

  01. Change the Deivse default identifier from email to user_id.
      see: https://github.com/heartcombo/devise#strong-parameters :the section Strong Paramters
      .... edit ApplicationController for a "before_action" to sanitize and allow new params.
      Then, edit  /config/initializers/devise.rb  ...  to have:
          config.authentication_keys = [:user_id]
              ...and...
          config.strip_whitespace_keys = [:user_id]

      This allows ...  POST  http://localhost:3001/login   with...
       { "user": { "user_id": "js1", "password": "js1111" } }
      ...to work.

  02. How do other controllers (non-user) ensure authentication?
    a. See discussion of "acts_as_token_authentication_handler in
       https://wajeeh-ahsan.medium.com/rails-user-authentication-with-devise-and-simple-token-authentication-7beafd1bb863
    b. See class MembersController < ApplicationController
          before_action :authenticate_user!
       https://medium.com/ruby-daily/a-devise-jwt-tutorial-for-authenticating-users-in-ruby-on-rails-ca214898318e

  03. To add "Refresh" feature, see devise.rb   ....  config.jwt setup discussion in
      https://fifth-sama.medium.com/rails-devise-jwt-tutorial-b5d5b03d9040
      ... also see the section on config/initializers/devise.rb in the 
      sdrmike.medium.com/...authentication... post, suggests that any positive return to POST
      will cause a JWT Auth token to be appended to reply pkt header...

      See this posting: https://github.com/waiting-for-dev/devise-jwt/issues/7 for 
          refresh discussion.

      Note: Currently the phone app sends   , 'PATCH relays/refresh'
            with: authroization hdr = "Bearer jwt_rrt"  ... and .., 
            popps_body = JSON.stringify({device_guid: dvc_id})

      Note: To store a jwt_rrt, send  "POST /relays/register/ "
            With valid jwt_uat in Auth hdr and Body: {device_guid, device_description}

      Note: Content of jwt_rrt is
            internally constructed  JSON Stringified form of
             {userid: user_id, device_guid: device_guid}

      REVIEW OF DEVISE / WARDEN SOURCE .....
      Found that - app/controllers/users/sessions_controller.rb inherits
                   from Devise::SessionsController.
                 - sign_in is processed at Devise::SessionsController::create()
                 - "intercept" create() in app/contollers/users/sessions_controller.rb
                 - check for jwt_rrt in body JSON.
                 - if absent, then "super" to create() in Devise for pwd login...
                 - otherwise, reproduce the Devise::SessionsController logic to:
                   - validate jwt_rrt - decrypt, check device_ids, get user_id.
                   - retrieve User
                   - check that user_relay_registrations tbl entry exists
                   - call sign_in() and respond_with() function to complete login.

      Tested with Postman using non-encrypted mock jwt_rrt and skipping the
      user_relay_registrations lookup/check.   ==> Seems to work!!!!!

      NEXT:
      - Clean up routing to user_relay_registrations.
        Note: USEFUL - in a controller, after "before_action :authenticate_user!"
              a "current_user" variable is available.
      - Research JWT Encryption for jwt_rrt.
      - Test POST user_relay_registration  => return jwt_rrt.
        Note: disallow duplicates.
      - Test lookup check in session_controller.rb create() processing.
      - Test DELETE user_relay_registration.

      Generate controllers:
      rails g controller api/v1/user_controller
      rails g controller api/v1/user_relay_registration_controller

      Generate models: (note: User model already exists)
      rails g model user_relay_registration --no-migration   ..already created this...

      rrt_jwt format: 
        var claims = {
                iss: CONFIG.POPPS_APP,   ... currently this is "https://popps.com"  ??
                sub: lcl_rrt_sub_encrypt(userid, deviceid),
                popps_type: "rrt"
        }
      ...encrypted sub is  JSON.stringify({user_id: user_id, device_guid: device_guid});

      Need a "Service Object" to handle JWT & Enctryption tasks.
      - For secret use: Rails.application.credentials.devise_jwt_secret_key!
      - Use JWT gem - see https://www.rubydoc.info/gems/jwt/1.5.4
      - Encrypt/decrypt example: 
        https://dev.to/shobhitic/simple-string-encryption-in-rails-36pi




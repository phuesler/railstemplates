# This installs Authlogic stuff at the moment but could support others too

gem 'authlogic'

generate 'session', 'user_session'

user_model = ENV['USER_MODEL'] || ask("What should be the name of the user model? (leave it empty to skip)")

return if user_model.blank?
user_ident = ENV['USER_IDENT'] || ask("What is the identifier of a user? (e.g. login, email)")

migration = "#{user_ident}:string crypted_password:string password_salt:string persistence_token:string single_access_token:string perishable_token:string login_count:integer last_request_at:datetime current_login_at:datetime last_login_at:datetime current_login_ip:string last_login_ip:string"

if File.exists?('vendor/plugins/rspec')
  generate 'rspec_model', user_model, migration
else
  generate 'model', user_model, migration
end

user_model.downcase!

file "app/models/#{user_model.downcase.underscore}.rb", <<-RB
class #{user_model.classify} < ActiveRecord::Base
acts_as_authentic # for options see documentation: Authlogic::ORMAdapters::ActiveRecordAdapter::ActsAsAuthentic::Config
end
RB

file 'app/controllers/application_controller.rb', <<-AUTHLOGIC
class ApplicationController < ActionController::Base
  protect_from_forgery
  filter_parameter_logging "password" unless Rails.env.development?
  
  # Authlogic-specific helper methods
  helper_method :current_user

  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end

    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to account_url
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
end
AUTHLOGIC


# Create UserSession controller and minimal log-in/-out views
file File.join("app", "controllers", "#{user_model}_sessions_controller.rb"), <<-USERSESSIONS
class #{user_model.classify}SessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    @#{user_model}_session = #{user_model.classify}Session.new
  end

  def create
    @#{user_model}_session = #{user_model.classify}Session.new(params[:#{user_model}_session])
    if @#{user_model}_session.save
      flash[:notice] = "Successfully logged in."
      redirect_back_or_default root_url
    else
      render :action => 'new'
    end
  end

  def destroy
    @#{user_model}_session = #{user_model.classify}Session.find
    @#{user_model}_session.destroy
    flash[:notice] = "Successfully logged out."
    redirect_back_or_default root_url
  end
end
USERSESSIONS

route "map.resources :#{user_model}_sessions"
route "map.login 'login', :controller => '#{user_model}_sessions', :action => 'new'"
route "map.logout 'logout', :controller => '#{user_model}_sessions', :action => 'destroy'"
route "map.root :controller => 'application', :action => 'index'"

file File.join("app", "views", "application", "index.html.haml"), <<-INDEX
%h1 Welcome page
INDEX

  file File.join("app", "views", "#{user_model}_sessions", "new.html.haml"), <<-NEW
%h1 Log in
- form_for @#{user_model}_session do |f|
  = f.error_messages
  %p
    = f.label :#{user_ident}
    %br/
    = f.text_field :#{user_ident}
  %p
    = f.label :password
    %br/
    = f.password_field :password
  %p
    = f.submit "Submit"
NEW

# Generate minimal user controller
file File.join("app", "controllers", "#{user_model.pluralize}_controller.rb"), <<-USERS
class #{user_model.classify.pluralize}Controller < ApplicationController
  #before_filter :require_no_user, :only => [:new, :create]
  #before_filter :require_user, :only => [:show, :edit, :update]

  def new
    @#{user_model} = #{user_model.classify}.new
  end

  def create
    @#{user_model} = #{user_model.classify}.new(params[:#{user_model}])
    if @#{user_model}.save
      flash[:notice] = "Registration successful."
      redirect_back_or_default root_url
    else
      render :action => 'new'
    end
  end

  def edit
    @#{user_model} = current_user
  end

  def update
    @#{user_model} = current_user
    if @#{user_model}.update_attributes(params[:#{user_model}])
      flash[:notice] = "Successlfuly updated #{user_model}."
      redirect_to #{user_model.pluralize}_url
    else
      render :action => 'edit'
    end
  end
end
USERS

route "map.resources :#{user_model.pluralize}"

# Create create/edit views
  file File.join("app", "views", user_model.pluralize, "new.html.haml"), <<-NEW
%h2 New #{user_model.classify}
= render :partial => 'form'
%p
  = link_to "Back to List", #{user_model.pluralize}_path
NEW

  file File.join("app", "views", user_model.pluralize, "edit.html.haml"), <<-EDIT
%h2 Edit #{user_model.classify}
= render :partial => 'form'
%p
  = link_to "Show", @#{user_model}
  |
  = link_to "View All", #{user_model.pluralize}_path
EDIT

  file File.join("app", "views", user_model.pluralize, "_form.html.haml"), <<-FORM
-form_for @#{user_model} do |f|
  = f.error_messages
  %p
    = f.label :#{user_ident}
    %br/
    = f.text_field :#{user_ident}
  %p
    = f.label :password
    %br/
    = f.password_field :password
  %p
    = f.label :password_confirmation
    %br/
    = f.password_field :password_confirmation
  %p
    = f.submit "Submit"
FORM

  file File.join("app", "views", user_model.pluralize, "_user_nav.html.haml"), <<-USERNAV
#user-nav
  - if current_user
    = link_to "Edit Profile", edit_#{user_model}_path(:current)
    |
    = link_to "Logout", logout_path
  - else
    = link_to "Register", new_#{user_model}_path
    |
    = link_to "Login", login_path
USERNAV

log "NOTE", "Don't forget to run 'rake db:migrate'."
git :add => "."
git :commit => "-a -m 'Added AuthLogic#{" and #{user_model} model" unless user_model.blank?}'"

def initialize(*args)
  super
  
  package "git-core"
end

action :deploy do
  directory "#{new_resource.install_in}" do
    recursive true
    owner "torquebox"
    group "torquebox"
  end
  
  timestamped_deploy "#{new_resource.install_in}/#{new_resource.name}" do
    repo new_resource.git_repository
    branch "master"
    revision "HEAD"
    user "torquebox"
    group "torquebox"
    enable_submodules false
    migrate false
    # migrate_command ""
    environment "RACK_ENV" => "production"
    shallow_clone true
    action :deploy
    restart_command do
    end
    # git_ssh_wrapper "wrap-ssh4git.sh"
    scm_provider Chef::Provider::Git
    purge_before_symlink %w{}
    create_dirs_before_symlink %w{}
    symlinks Hash.new # {} doesn't work, as it gets parsed as a block
    symlink_before_migrate Hash.new
  end
  
  deployed_path = "#{new_resource.install_in}/#{new_resource.name}/current"
  
  # Construct/clobber the YAML file
  require "yaml"
  file "#{deployed_path}/config/torquebox.yml" do
    content new_resource.configuration.to_yaml
  end
  
  execute "bundle install" do
    command "jruby -S bundle install"
    cwd "#{deployed_path}"
    not_if "jruby -S bundle check"
  end
  
  # Takes way too long
  # execute "compile assets" do
  #   command "jruby -S bundle exec rake assets:precompile"
  #   cwd "#{new_resource.install_in}/#{new_resource.name}"
  #   environment "RAILS_ENV" => "production", "JRUBY_OPTS" => node[:torquebox][:jruby][:opts]
  # end
  
  torquebox_application "tb_app:#{new_resource.name}" do
    action :deploy
    path "#{deployed_path}"
  end
end

action :undeploy do
  torquebox_application "tb_app:#{new_resource.name}" do
    action :undeploy
    path "#{deployed_path}"
  end
end

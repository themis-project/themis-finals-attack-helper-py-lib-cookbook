id = 'themis-finals-attack-helper-py-lib'
h = ::ChefCookbook::Instance::Helper.new(node)

directory node[id]['basedir'] do
  owner h.instance_user
  group h.instance_group
  mode 0755
  recursive true
  action :create
end

url_repository = "https://github.com/#{node[id]['github_repository']}"

if node.chef_environment.start_with? 'development'
  ssh_private_key h.instance_user
  ssh_known_hosts_entry 'github.com'
  url_repository = "git@github.com:#{node[id]['github_repository']}.git"
end

git2 node[id]['basedir'] do
  url url_repository
  branch node[id]['revision']
  user h.instance_user
  group h.instance_group
  action :create
end

if node.chef_environment.start_with? 'development'
  git_data_bag_item = nil
  begin
    git_data_bag_item = data_bag_item('git', node.chef_environment)
  rescue
    ::Chef::Log.warn 'Check whether git data bag exists!'
  end

  git_options = \
    if git_data_bag_item.nil?
      {}
    else
      git_data_bag_item.to_hash.fetch 'config', {}
    end

  git_options.each do |key, value|
    git_config "git-config #{key} at #{node[id]['basedir']}" do
      key key
      value value
      scope 'local'
      path node[id]['basedir']
      user h.instance_user
      action :set
    end
  end
end

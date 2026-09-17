include_cookbook 'systemd'
include_cookbook 'repository'

remote_file '/home/isucon/env' do
  owner 'isucon'
  group 'isucon'
  mode  '0644'
end

execute 'install webapp' do
  command <<-EOS
  rm -rf /home/isucon/webapp
  cp -a #{node[:isucon11_repository]}/webapp /home/isucon/webapp
  cp #{node[:isucon11_repository]}/REVISION /home/isucon/webapp/REVISION
  chown -R isucon:isucon /home/isucon/webapp
  EOS
  cwd '/home/isucon'
  not_if "test -d /home/isucon/webapp && test -f /home/isucon/webapp/REVISION && test $(cat /home/isucon/webapp/REVISION) = $(cat #{node[:isucon11_repository]}/REVISION)"

  notifies :run, 'execute[/home/isucon/webapp/tools/initdb]', :immediately
  notifies :restart, 'service[web-golang]'
end

execute '/home/isucon/webapp/tools/initdb' do
  action :nothing
  user 'isucon'
  cwd '/home/isucon/webapp'
end

# systemctl

remote_file '/etc/systemd/system/web-golang.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[web-golang]'
end

# golang

execute '/home/isucon/.x make build' do
  user 'isucon'
  cwd '/home/isucon/webapp/golang'
end

service 'web-golang' do
  action [:enable, :start]
end

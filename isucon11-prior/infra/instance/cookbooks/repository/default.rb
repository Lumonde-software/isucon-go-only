node[:isucon11_repository] = '/home/isuadmin/src/isucon11-prior'

execute 'clone repository' do
  command <<-EOC
  rm -rf /tmp/isucon-go-only
  git clone --depth=1 --filter=blob:none --sparse https://github.com/Lumonde-software/isucon-go-only.git /tmp/isucon-go-only
  git -C /tmp/isucon-go-only sparse-checkout set isucon11-prior
  git -C /tmp/isucon-go-only rev-parse HEAD > /tmp/isucon-go-only/isucon11-prior/REVISION
  mkdir -p $(dirname #{node[:isucon11_repository]})
  mv /tmp/isucon-go-only/isucon11-prior #{node[:isucon11_repository]}
  rm -rf /tmp/isucon-go-only
  EOC
  user 'isuadmin'
  not_if "test -d #{node[:isucon11_repository]}"

  notifies :run, 'execute[build frontend]', :immediately
end

execute 'build frontend' do
  action :nothing
  command <<-EOS
  /home/isucon/.x yarn install --frozen-lockfile
  /home/isucon/.x yarn build
  rm -rf node_modules
  EOS
  user 'isuadmin'
  cwd "#{node[:isucon11_repository]}/webapp/frontend"
end

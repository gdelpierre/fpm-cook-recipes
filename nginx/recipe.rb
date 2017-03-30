class Nginx < FPM::Cookery::Recipe

  description    "nginx web/proxy server (extended version)
                  Nginx ('engine X') is a high-performance web and reverse proxy server
                  created by Igor Sysoev. It can be used both as a standalone web server
                  and as a proxy to reduce the load on back-end HTTP or mail servers.
                  .
                  This package provides a version of nginx with the standard modules,
                   plus  extra features and modules such as the Perl module, which 
                  allows the addition of Perl in configuration files."

  name          'nginx-custom'
  version       '1.11.10'
  revision      "1"
  maintainer    'gde <gde@llew.me>'
  arch          'amd64'
  homepage      'http://nginx.net'
  section       'httpd'
  source        "http://nginx.org/download/nginx-#{version}.tar.gz"

  build_depends 'libc6 (>= 2.14)', 'libexpat1 (>= 2.0.1)', 'libgd3 (>= 2.1.0~alpha~)',
                'libgeoip-dev', 'libluajit-5.1-2', 'libpam0g (>= 0.99.7.1)', 'libpcre3-dev',
                'libssl-dev', 'libxml2 (>= 2.7.4)',
                'libxslt1.1 (>= 1.1.25)', 'zlib1g (>= 1:1.1.4)'

  depends       'libpcre3', 'libssl1.0.0 (>= 1.0.2~beta3)', 'libgeoip1', 'libluajit-5.1-2'

  conflicts     'nginx-core', 'nginx-full', 'nginx-light', 'nginx-common', 'nginx'
  replaces      'nginx-core', 'nginx-full', 'nginx-common', 'nginx-light', 'nginx'

  pre_install    'preinst'
  post_install   'postinst'
  post_uninstall 'postrm'

  provides      "#{name}"

  @@additionnals_modules = %w(ngx_http_geoip2_module ngx_dev_kit ngx_http_lua_module
                           ngx_http_upstream_fair_module ngx_http_headers_more_filter_module
                           ngx_http_echo_module ngx_http_auth_ldap_module)

  def build

    maxmind_version ||= '1.2.0'
    ngx_dev_kit ||= '0.3.0'
    mod_geoip_version ||= '2.0'
    mod_lua_version ||= '0.10.7'
    mod_headers_version ||= '0.32'
    mod_ngx_echo ||= '0.60'
    mod_upstream_fair ||= '0.1.1'

    _modules ||= []

    Dir.mkdir "modules"
    Dir.chdir 'modules' do
      # geoip dep
      safesystem "wget https://github.com/maxmind/libmaxminddb/releases/download/#{maxmind_version}/libmaxminddb-#{maxmind_version}.tar.gz -O libmaxminddb.tar.gz"
      safesystem "wget https://github.com/leev/ngx_http_geoip2_module/archive/#{mod_geoip_version}.tar.gz -O ngx_http_geoip2_module.tar.gz"
      # lua dep
      safesystem "wget https://github.com/simpl/ngx_devel_kit/archive/v#{ngx_dev_kit}.tar.gz -O ngx_dev_kit.tar.gz"
      safesystem "wget https://github.com/openresty/lua-nginx-module/archive/v#{mod_lua_version}.tar.gz -O ngx_http_lua_module.tar.gz"

      safesystem "wget https://github.com/itoffshore/nginx-upstream-fair/archive/v#{mod_upstream_fair}.tar.gz -O ngx_http_upstream_fair_module.tar.gz"
      safesystem "wget https://github.com/openresty/headers-more-nginx-module/archive/v#{mod_headers_version}.tar.gz -O ngx_http_headers_more_filter_module.tar.gz"
      safesystem "wget https://github.com/openresty/echo-nginx-module/archive/v#{mod_ngx_echo}.tar.gz -O ngx_http_echo_module.tar.gz"
      safesystem 'wget https://github.com/kvspb/nginx-auth-ldap/tarball/master -O ngx_http_auth_ldap_module.tar.gz'

      _modules.push(*@@additionnals_modules).push('libmaxminddb')

      _modules.each do |mod|
        Dir.mkdir "#{mod}"
        safesystem "tar xzf #{mod}.tar.gz -C #{mod} --strip-component 1"
      end

      Dir.chdir "libmaxminddb" do
        configure
        make 'check'
        make 'install'
        safesystem 'ldconfig'
      end
    end

    _cc_opts = %Q#-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2#
    _ld_opts = %Q#-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -fPIC#
    _with_opts = %W( cc-opt=\'#{_cc_opts}\'
               ld-opt=\'#{_ld_opts}\'
               debug
               http_auth_request_module
               http_realip_module
               http_stub_status_module
               http_ssl_module
               http_gzip_static_module
               http_v2_module
               http_slice_module
               http_addition_module
               http_flv_module
               http_geoip_module=dynamic
               http_gunzip_module
               http_gzip_static_module
               http_image_filter_module=dynamic
               http_mp4_module
               http_random_index_module
               http_secure_link_module
               http_sub_module
               http_xslt_module=dynamic
               mail=dynamic
               mail_ssl_module
               pcre-jit
               stream=dynamic
               stream_ssl_module
               threads
               )

    _build_opts = ' --with-' + _with_opts.join(' --with-')
    _dynamic_mods = ' --add-dynamic-module=modules/' + @@additionnals_modules.join(' --add-dynamic-module=modules/')

    # Can't use module `configure` because of L28 to L41
    # https://github.com/bernd/fpm-cookery/blob/master/lib/fpm/cookery/utils.rb
    safesystem %Q(./configure
               #{_build_opts}
               #{_dynamic_mods}
               --prefix=/usr/lib/nginx
               --user=www-data
               --group=www-data
               --conf-path=/etc/nginx/nginx.conf
               --http-log-path=/var/log/nginx/access.log
               --error-log-path=/var/log/nginx/error.log
               --lock-path=/var/lock/nginx.lock
               --pid-path=/run/nginx.pid
               --modules-path=/usr/lib/nginx/modules
               --http-client-body-temp-path=/var/lib/nginx/body
               --http-fastcgi-temp-path=/var/lib/nginx/fastcgi
               --http-proxy-temp-path=/var/lib/nginx/proxy
               --http-scgi-temp-path=/var/lib/nginx/scgi
               --http-uwsgi-temp-path=/var/lib/nginx/uwsgi
               ).gsub(/\n/, '')

    make
  end

  def install
    # Create needed dirs
    %w( nginx/conf.d nginx/sites-available nginx/modules-available logrotate.d
    nginx/snippets nginx/sites-enabled nginx/modules-enabled ).each { |dir| etc(dir).mkpath }

    %w( log/nginx lib/nginx ).each { |dir| var(dir).mkpath }
    %w( nginx/modules nginx/modules-available ).each { |dir| lib(dir).mkpath }
    share('nginx/modules-available').mkpath

    # bin server
    sbin.install Dir['objs/nginx']

    # modules shared lib
    FileUtils.chmod 0644, Dir['objs/*.so']
    lib('nginx/modules').install Dir['objs/*.so']

    # modules file
    @@additionnals_modules.push('ndk_http_module.so').map do |mod|
      File.write(lib("nginx/modules-available/#{mod}.conf"), "load_module modules/#{mod}.so;")
      File.write(etc("nginx/modules-available/#{mod}.conf"), "load_module modules/#{mod}.so;")
    end

    # startup script
    root('lib/systemd/system').install workdir('nginx.service')

    # default
    etc('default').install workdir('nginx-etc-default') => 'nginx'

    # simple default ufw file
    etc('ufw/applications.d').install workdir('nginx-ufw') => 'nginx'

    # logrotate
    etc('logrotate.d').install workdir('nginx-logrotate') => 'nginx'

    # config files
    etc('nginx').install Dir['conf/*']

    # default site
    var('www/html').install Dir['html/*']

    # default nginx vhost
    etc('nginx/sites-available').install workdir('nginx-default-vhost') => 'default'

    # man page
    man8.install Dir['objs/nginx.8']
    safesystem 'gzip', man8/'nginx.8'
  end

end

class Php_cassandra < FPM::Cookery::Recipe

  name          'php-cassandra-driver'
  version       '1.3.0'
  homepage      'https://github.com/datastax/php-driver'
  source        "#{homepage}",
    :with      => :git,
    :tags      => "v#{version}",
    :submodule => true

  revision      '1'
  maintainer    'Llew <gde@llew.me>'
  arch          'amd64'
  description   'DataStax PHP Driver for Apache Cassandra'
  section       'php'

  build_depends 'libc6 (>= 2.17)', 'cmake', 'php-dev', 'cassandra-cpp-driver (>= 2.6.0)', 'libuv1-dev'
  depends       'libc6 (>= 2.17)', 'php-common (>= 1:7.0+33~)', 'phpapi-20151012 | phpapi-20160303', 'cassandra-cpp-driver (>= 2.6.0)', 'libuv1'
  provides      "#{name}"

  pre_uninstall 'prerm'
  post_install  'postinst'

  def build
    Dir.mkdir 'build'
    Dir.chdir 'build' do
      system 'cmake -DCMAKE_CXX_FLAGS="-fPIC" -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCASS_BUILD_STATIC=ON'\
             ' -DCASS_BUILD_SHARED=OFF -DCMAKE_BUILD_TYPE=RELEASE -DCASS_USE_ZLIB=ON'\
             ' -DCMAKE_INSTALL_LIBDIR:PATH=/usr/lib ../lib/cpp-driver/'
      system 'make && make install'
      File.rename('libcassandra_static.a', 'libcassandra.a')
      Dir.mkdir 'lib'
      Dir.entries('.').select { |f| File.fnmatch('libcassandra*', f) && File.file?(f) }.each do |filename|
        FileUtils.mv(filename, 'lib/')
      end
    end
    Dir.chdir 'ext' do
      system 'phpize'
      system 'LIBS="-lssl -lz -luv -lm -lstdc++"'\
              ' LDFLAGS="-L../build/lib"'\
             ' ./configure --with-cassandra --with-lib=../build/lib'
      system 'make'
    end
  end

  def install
    Dir.chdir 'ext' do
      %w( 20151012 20160303 ).each do |version|
        prefix("lib/php/#{version}/").install 'modules/cassandra.so'
      end
      %w( 7.0 7.1 ).each do |php_version|
        etc("php/#{php_version}/mods-available/").install workdir('cassandra.ini')
      end
    end
  end

end

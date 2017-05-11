class Prometheus < FPM::Cookery::Recipe

  name          'prometheus'

  description   'Prometheus Monitoring Framework'

  version       '1.6.1'
  source        "https://github.com/#{name}/#{name}/releases/download/v#{version}/#{name}-#{version}.linux-amd64.tar.gz"
  homepage      'https://www.prometheus.io/'

  revision      'm6web1'
  maintainer    'M6Web <sysadmin@m6web.fr>'
  arch          'amd64'
  section       'net'

  provides      "#{name}"

  def build
  end

  def install
    var("lib/#{name}").mkpath

    etc("#{name}").install 'prometheus.yml'
    bin.install %w( prometheus promtool )
    var("lib/#{name}").install %w( consoles console_libraries )

    root('lib/systemd/system').install workdir('prometheus.service')
    etc('default').install workdir('prometheus-etc-default') => 'prometheus' 
  end

end

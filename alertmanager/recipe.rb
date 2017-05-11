class Alertmanager < FPM::Cookery::Recipe

  name          'alertmanager'

  description   'The Alertmanager handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver integrations such as email, PagerDuty, or OpsGenie. It also takes care of silencing and inhibition of alerts.'

  version       '0.6.2'
  source        "https://github.com/prometheus/#{name}/releases/download/v#{version}/#{name}-#{version}.linux-amd64.tar.gz"
  homepage      'http://prometheus.io/docs/alerting/alertmanager/'

  revision      'm6web1'
  maintainer    'M6Web <sysadmin@m6web.fr>'
  arch          'amd64'
  section       'net'

  provides      "#{name}"

  def build
  end

  def install
    var("lib/#{name}").mkpath

    etc("#{name}").install 'simple.yml' => 'alertmanager.yml'
    bin.install 'alertmanager'

    root('lib/systemd/system').install workdir('alertmanager.service')
    etc('default').install workdir('alertmanager-etc-default') => 'alertmanager' 
  end

end

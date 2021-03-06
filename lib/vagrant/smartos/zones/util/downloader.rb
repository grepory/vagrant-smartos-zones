module Vagrant
  module Smartos
    module Zones
      module Util
        class Downloader
          def self.get(url, path)
            new.get(url, path)
          end

          def get(url, path)
            self.send(download_utility, url, path)
          end

          private

          def download_utility
            if system('which wget >/dev/null')
              'wget'
            else
              'curl'
            end
          end

          def wget(url, path)
            `wget #{url} -O #{path} --quiet`
          end

          def curl(url, path)
            `curl #{url} -o #{path} --silent`
          end
        end
      end
    end
  end
end

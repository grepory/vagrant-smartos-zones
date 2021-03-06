module Vagrant
  module Smartos
    module Zones
      module Cap
        class ZoneCreate
          def self.zone_create(machine)
            ui = machine.ui

            if zone_valid?(machine)
              name = machine.config.zone.name
              if zone_exists?(machine)
                ui.info "Zone #{name} exists"
                ui.info "Updating..."
                update_zone(machine)
              else
                ui.info "Creating zone #{name} with image #{machine.config.zone.image}"
                create_zone(machine)
                ui.info "Zone created with uuid #{zone_uuid(machine)}"
              end
            else
              ui.info "No zone configured, skipping"
              ui.info "   add the following to your Vagrantfile to configure a local zone:"
              ui.info "      config.zone.name      = 'my-zone'"
              ui.info "      config.zone.image     = 'uuid'"
              ui.info "      config.zone.brand     = 'joyent'"
              ui.info "      config.zone.memory    = 2048"
              ui.info "      config.zone.disk_size = 5"
            end
          end

          def self.create_zone(machine)
            sudo = machine.config.smartos.suexec_cmd
            machine.communicate.execute("echo '#{zone_json(machine)}' | #{sudo} vmadm create")
            machine.guest.capability(:create_zone_users)
          end

          def self.update_zone(machine)
            sudo = machine.config.smartos.suexec_cmd
            machine.communicate.execute("echo '#{zone_json(machine)}' | #{sudo} vmadm update #{zone_uuid(machine)}")
          end

          def self.zone_json(machine)
            {
              "brand" => machine.config.zone.brand,
              "alias" => machine.config.zone.name,
              "dataset_uuid" => machine.config.zone.image,
              "quota" => machine.config.zone.disk_size || 1,
              "max_physical_memory" => machine.config.zone.memory || 64,
              "resolvers" => [
                "8.8.8.8",
                "8.8.4.4"
              ],
              "nics" => [
                { "nic_tag" => "admin", "ip" => "dhcp"}
              ]
            }.to_json
          end

          def self.zone_exists?(machine)
            name = machine.config.zone.name
            sudo = machine.config.smartos.suexec_cmd

            machine.communicate.test("#{sudo} vmadm list -H | awk '{print $5}' | grep #{name}")
          end

          def self.zone_uuid(machine)
            sudo = machine.config.smartos.suexec_cmd
            uuid = ''
            machine.communicate.execute("#{sudo} vmadm lookup alias=#{machine.config.zone.name}") do |type, output|
              uuid << output
            end
            uuid
          end

          def self.zone_valid?(machine)
            machine.config.zone && machine.config.zone.image && machine.config.zone.name
          end

          def self.list_zones(machine)
            sudo = machine.config.smartos.suexec_cmd
            zones = ''

            machine.communicate.execute("#{sudo} vmadm list -H", {}) do |type, output|
              zones << output
            end

            zones.split("\n")
          end
        end
      end
    end
  end
end

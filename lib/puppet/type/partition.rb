# encoding: UTF-8
require 'pathname'
$:.unshift(Pathname.new(__FILE__).dirname.parent.parent)
$:.unshift(Pathname.new(__FILE__).dirname.parent.parent.parent.parent + 'easy_type' + 'lib')
require 'utils/parted'

# @nodoc
module Puppet
  newtype(:partition) do
    include EasyType
    include EasyType::Helpers

    desc "create and modify partitions on a disk"

    ensurable

    set_command(:parted)

    to_get_raw_resources do
      parted = Utils::Parted.new
      parted.partitions
    end

    on_create do | command_builder |
      if start.nil?
        start = Puppet::Util::Execution.execute("parted #{device} unit s print free |grep 'Free Space' | awk '{print $1}' ").chop
        Puppet.info "No start defined. Using sector #{start} as start"
      end

      if self[:end].nil?
        self[:end] = Puppet::Util::Execution.execute("parted #{device} unit s print free |grep 'Free Space' | awk '{print $2}' ").chop
        Puppet.info "No end was defined. Using sector #{self[:end]} as end"
      end

      parameter = part_type ? part_type : part_name
      "-s #{device} mkpart #{parameter} #{start} #{self[:end]}"
    end

    on_modify do | command_builder|
      "-s #{device}"
    end

    on_destroy do |command_builder|
      "-s #{device} rm #{minor}"
    end

    #
    # Title is device/name
    #
    map_title_to_attributes(:name, :device, :minor) do
      /^((.*):(.*))$/
    end

    parameter :name
    parameter :device
    parameter :minor
		property  :start
		property  :end
		property  :fs_type
		property  :part_type
    property  :part_name
		property  :boot
		property  :lba
		property  :root
		property  :swap
		property  :hidden
		property  :raid
		property  :lvm
    # -- end of attributes -- Leave this comment if you want to use the scaffolder
    #
  end
end

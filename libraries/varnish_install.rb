class Chef
  class Resource
    # Install Varnish
    class VarnishInstall < Chef::Resource::LWRPBase
      self.resource_name = :varnish_install
      actions :install
      default_action :install

      attribute :name, kind_of: String, name_attribute: true
      attribute :package_name, kind_of: String, default: 'varnish'
      attribute :package_version, kind_of: String
      attribute :vendor_repo, kind_of: [TrueClass, FalseClass], default: false
      attribute :vendor_version, kind_of: String, default: '4.0'
    end
  end

  class Provider
    # Install Varnish
    class VarnishInstall < Chef::Provider::LWRPBase
      include VarnishCookbook::Helpers

      use_inline_resources

      def whyrun_supported?
        true
      end

      def action_install
        if new_resource.vendor_repo
          add_vendor_repo
        end

        install_varnish
      end

      def add_vendor_repo
        # packagecloud repos omit dot from major version
        major_version_no_dot = new_resource.vendor_version.to_s.tr('.', '')
        case node['platform_family']
        when 'debian'
          repo = apt_repository 'varnish-cache' do
            uri "https://packagecloud.io/varnishcache/varnish#{major_version_no_dot}/#{node['platform']}"
            distribution node['lsb']['codename']
            components ['main']
            key "https://packagecloud.io/varnishcache/varnish#{major_version_no_dot}/gpgkey"
            deb_src true
          end
          repo.run_action(:add)
          new_resource.updated_by_last_action(true) if repo.updated_by_last_action?
        when 'rhel', 'fedora'
          repo = yum_repository 'varnish' do
            description "Varnish #{new_resource.vendor_version} repo (#{node['platform_version']} - $basearch)"
            url "https://packagecloud.io/varnishcache/varnish#{major_version_no_dot}/el/#{node['platform_version'].to_i}/$basearch"
            gpgcheck false
            gpgkey "https://packagecloud.io/varnishcache/varnish#{major_version_no_dot}/gpgkey"
          end
          repo.run_action(:create)
          new_resource.updated_by_last_action(true) if repo.updated_by_last_action?
        end
      end

      def install_varnish
        # The reload-vcl script doesn't support the -j option and breaks reload on debian/ubuntu.
        reload_vcl = cookbook_file '/usr/share/varnish/reload-vcl' do
          action :nothing
          source 'reload-vcl'
          cookbook 'varnish'
          only_if { platform_family?('debian') && varnish_version.join('.').to_f >= 4.1 }
        end

        svc = service 'varnish' do
          supports restart: true, reload: true
          action :nothing
        end

        pack = package new_resource.package_name do
          action :nothing
          version new_resource.package_version unless new_resource.package_version.nil?
          notifies 'enable', "service[#{new_resource.package_name}]", 'delayed'
          notifies 'restart', "service[#{new_resource.package_name}]", 'delayed'
        end

        pack.run_action(:install)
        if pack.updated_by_last_action?
          reload_vcl.run_action(:create)
          svc.run_action(:enable)
          svc.run_action(:restart)
        end

        # The latest vendor package does not create the varnishlog group but expects it to exist if varnishlog is
        # enabled on debian systems
        group 'varnishlog' do
          system true
          members 'varnishlog'
          only_if { node['platform_family'] == 'debian' }
        end.run_action(:create)

        new_resource.updated_by_last_action(true) if svc.updated_by_last_action? || pack.updated_by_last_action?
      end
    end
  end
end

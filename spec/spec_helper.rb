class Specinfra::Command::Busybox
  class Base < Specinfra::Command::Linux::Base
    class Group < Specinfra::Command::Base::Group
      class << self
        def check_exists(group)
          "grep #{escape(group)} /etc/group"
        end

        def check_has_gid(group, gid)
          "grep #{escape(group)} /etc/group | cut -f 3 -d ':' | grep -w -- #{escape(gid)}"
        end
      end
    end

    class RoutingTable < Specinfra::Command::Base::RoutingTable
      class << self
        def check_has_entry(destination)
          %Q{ip route show #{destination} | awk '{print $1, "via", $5, "dev", $3, " "}'}
        end

        alias :get_entry :check_has_entry
      end
    end

    class User < Specinfra::Command::Base::User
      class << self
        def check_has_home_directory(user, path_to_home)
          "grep #{escape(user)} /etc/passwd | cut -f 6 -d ':' | grep -w -- #{escape(path_to_home)}"
        end

        def check_has_login_shell(user, path_to_shell)
          "grep #{escape(user)} /etc/passwd | cut -f 7 -d ':' | grep -w -- #{escape(path_to_shell)}"
        end
      end
    end
  end
end

class Specinfra::Helper::DetectOs::DockerRoot < Specinfra::Helper::DetectOs
  def detect
    if ( uname = run_command('uname -r').stdout ) && uname =~ /docker-root/i
      family = nil
      release = nil
      os_release = run_command("cat /etc/os-release")
      if os_release.success?
        os_release.stdout.each_line do |line|
          family = line.split('=').last.strip if line =~ /^ID_LIKE=/
          release = line.split('=').last.strip if line =~ /^VERSION=/
        end
      end
      family ||= 'linux'
      { :family => family, :release => release }
    end
  end
end

class Settings

    @@user_defaults = NSUserDefaults.standardUserDefaults

    class << self
        def position
            @@user_defaults.integerForKey('event_position')
        end

        def position=(pos)
            @@user_defaults.setInteger(pos, :forKey => 'event_position')
        end

        def launch_at_login?
            @@user_defaults.integerForKey('launch_at_login')
        end

        def launch_at_login=(val)
            @@user_defaults.setInteger(val, :forKey => 'launch_at_login')
        end
    end

end
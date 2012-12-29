module Settings

    @@user_defaults = NSUserDefaults.standardUserDefaults

    def self.position
        @@user_defaults.integerForKey('event_position')
    end

    def self.position=(pos)
        @@user_defaults.setInteger(pos, :forKey => 'event_position')
    end

    def self.launch_at_login?
        @@user_defaults.integerForKey('launch_at_login')
    end

    def self.launch_at_login=(val)
        @@user_defaults.setInteger(val, :forKey => 'launch_at_login')
    end

end
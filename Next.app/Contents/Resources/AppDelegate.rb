require 'event'
require 'settings'


class AppDelegate

    #Cocoa UI elements
    attr_accessor :menu, :eventName, :backButton, :skipButton, :launchAtLoginButton

    def applicationDidFinishLaunching(a_notification)
        @app_path = NSBundle.mainBundle.bundlePath

        @event = Event.new
        @event.add_observer(self, :handle_changes)

        init_menu
        init_statusbar_item

        start_update_loop

        handle_changes
    end

    def init_menu
        menu.setAutoenablesItems(false)
        eventName.setEnabled(false)
        backButton.setEnabled(@event.previous?)
        launchAtLoginButton.setState(Settings.launch_at_login?)

        launchAtLoginButton.setHidden(true)
    end

    def init_statusbar_item
        bar = NSStatusBar.systemStatusBar
        @statusbar_item = bar.statusItemWithLength(NSVariableStatusItemLength)
        icon_path = @app_path + '/Contents/Resources/en.lproj/icon-small.png'
        icon = NSImage.alloc.initWithContentsOfFile(icon_path)
        @statusbar_item.setImage(icon)
        @statusbar_item.setHighlightMode(true)
        @statusbar_item.setMenu(menu)
    end

    def start_update_loop
        NSTimer.scheduledTimerWithTimeInterval(
            60,
            :target => self,
            :selector => "update:",
            :userInfo => nil,
            :repeats => true
        )
    end

    def handle_changes
        update(nil, true)
    end

    def update(sender = nil, silent = false)
        puts 'DEBUG: update'

        time = @event.time
        if time.nil?
            show_notification unless silent
            @event.next
        else
            @statusbar_item.setTitle(time)
            eventName.setTitle(@event.title)
        end
    end

    def show_notification
        puts 'DEBUG: show notification'

        msg = NSUserNotification.alloc.init
        msg.title = @event.title
        msg.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.defaultUserNotificationCenter.deliverNotification(msg)
    end


    #events

    def skip(sender = nil)
        backButton.setEnabled(true) if @event.skip
        skipButton.setEnabled(false) unless @event.next?
    end

    def back(sender = nil)
        skipButton.setEnabled(true) if @event.back
        backButton.setEnabled(false) unless @event.previous?
    end

    def quit(sender = nil)
        puts 'DEBUG: quit'

        NSApp.terminate(nil)
    end


    def launchAtLogin(sender)
        url = NSURL.fileURLWithPath(@appPath)
        loginItems = LSSharedFileListCreate(nil, KLSSharedFileListSessionLoginItems, nil)

        if launchAtLoginButton.state == 0
            puts 'DEV: enable launch at login'

            if loginItems
                puts 'DEV: if loginItems'
                # TODO: program crashes in this line

                # inPropertiesToSet = CFDictionaryCreateMutable(nil, 1, nil, nil)
                # t = Pointer.new('B')
                # t.assign(1)
                # CFDictionaryAddValue(inPropertiesToSet, Pointer.new(KLSSharedFileListLoginItemHidden), t)

                item = LSSharedFileListInsertItemURL(loginItems, KLSSharedFileListItemLast, nil, nil, url, nil, nil)
                if item
                    puts 'DEV: if item'
                    CFRelease(item)
                end
            end

            CFRelease(loginItems)
            launchAtLoginButton.setState(1)
            Settings.launch_at_login = 1
        else
            puts 'DEV: disable launch at login'

            if loginItems
                puts 'DEV: if loginItems'
                seedValue = Pointer.new(:uint)

                loginItemsArray = LSSharedFileListCopySnapshot(loginItems, seedValue)
                loginItemsArray.each do |itemRef|
                    puts 'DEV: each'
                    puts itemRef
                    unless LSSharedFileListItemResolve(itemRef, 0, nil, nil).is_a? Exception
                        puts 'DEV: if LSSharedFileListItemResolve'
                        urlPath = url.path
                        if urlPath.compare(@appPath) == NSOrderedSame
                            puts 'DEV: if urlpath.compare'
                            LSSharedFileListItemRemove(loginItems, itemRef)
                        end
                    end
                end
            CFRelease(loginItemsArray)
            end
            launchAtLoginButton.setState(0)
            Settings.launch_at_login = 0
        end
    end

end
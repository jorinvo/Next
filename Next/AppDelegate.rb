#
#  AppDelegate.rb
#  Next
#
#  Created by jorin vogel on 11/29/12.
#  Copyright 2012 jorin vogel. All rights reserved.
#


class AppDelegate
    attr_accessor :menu, :eventName, :backButton, :skipButton, :launchAtLoginButton

    def applicationDidFinishLaunching(a_notification)
        @appPath = NSBundle.mainBundle.bundlePath
        @settings = NSUserDefaults.standardUserDefaults

        self.initCalendar
        self.initMenu
        self.initTimer
        self.update
    end

    def initMenu
        menu.setAutoenablesItems(false)

        bar = NSStatusBar.systemStatusBar

        @item = bar.statusItemWithLength(NSVariableStatusItemLength)
        @item.setImage(NSImage.alloc.initWithContentsOfFile(@appPath + '/Contents/Resources/en.lproj/icon-small.png'))
        @item.setHighlightMode(true)
        @item.setMenu(menu)

        backButton.setEnabled(@eventPosition > 0)
        eventName.setEnabled(false)
        launchAtLoginButton.setState(@settings.integerForKey('launchAtLoginState'))
    end

    def initCalendar
        @calendar = NSCalendar.currentCalendar
        @store = EKEventStore.alloc.initWithAccessToEntityTypes(EKEntityMaskEvent)

        NSNotificationCenter.defaultCenter.addObserver(
            self,
            :selector => "handleChanges:",
            :name => EKEventStoreChangedNotification,
            :object => @store
        )

        self.initData
    end

    def initTimer
        NSTimer.scheduledTimerWithTimeInterval(
            60,
            :target => self,
            :selector => "update:",
            :userInfo => nil,
            :repeats => true
        )
    end

    def sortEvents
        @events.sort! do |e1, e2|
            if e1.startDate.timeIntervalSinceNow < e2.startDate.timeIntervalSinceNow
                -1
            else
                1
            end
        end
    end

    def resetEvent
        @event = @events.first
        self.setPosition(0)
    end

    def update(timer = nil)
        puts 'DEBUG: update'

        time = self.getTime

        if time.nil?
            self.showNotification
            self.selectNext
        else
            @item.setTitle(time)
            eventName.setTitle(@event.title)
        end
    end

    def getTime
        time = @event.startDate.timeIntervalSinceNow
        if time < 60
            nil
        else
            self.humanize(time)
        end
    end

    def humanize(secs)
        if secs > 10368000
            "#{(secs / 5184000).to_i} months"
        elsif secs > 172800
            "#{(secs / 86400).to_i} days"
        else
            hours = (secs / 3600).to_i
            min = (secs.divmod(3600)[1] / 60).to_i
            min = '0' + min.to_s if min < 10

            "#{hours}:#{min}"
        end
    end

    def showNotification
        puts 'DEBUG: notify'

        msg = NSUserNotification.alloc.init
        msg.title = @event.title
        msg.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.defaultUserNotificationCenter.deliverNotification(msg)
    end

    def selectNext
        puts "DEBUG: select next event"

        @events.shift
        self.resetEvent
        self.update
    end

    def initData
        self.fetchEvents
        @eventPosition = @settings.integerForKey('eventPosition')
        @event = @events[@eventPosition]
    end

    def fetchEvents
        puts 'DEBUG: fetch events'

        start = NSDateComponents.alloc.init
        start.day = 0

        stop = NSDateComponents.alloc.init
        stop.year = 1

        predicate = @store.predicateForEventsWithStartDate(
            @calendar.dateByAddingComponents(
                start,
                :toDate => NSDate.date,
                :options => 0
            ),
            :endDate => @calendar.dateByAddingComponents(
                stop,
                :toDate => NSDate.date,
                :options => 0
            ),
            :calendars => nil
        )

        @events = @store.eventsMatchingPredicate(predicate)

        self.sortEvents
    end

    def handleChanges(evt = nil)
        puts 'DEBUG: handle changes'

        self.fetchEvents

        index = @events.index do |evt|
            evt.eventIdentifier == @event.eventIdentifier
        end
        self.resetEvent if index  != @eventPosition

        self.update
    end

    def setPosition(pos)
        @settings.setInteger(pos, :forKey => 'eventPosition')
        @eventPosition = pos
    end


    #events

    def skip(sender)
        puts "DEBUG: skip"

        newPos = @eventPosition + 1
        len = @events.length

        if len >= newPos
            self.setPosition(newPos)
            @event = @events[@eventPosition]

            self.update

            backButton.setEnabled(true)
        end

        skipButton.setEnabled(false) unless len > newPos
    end

    def back(sender)
        puts "DEBUG: back"

        newPos = @eventPosition - 1

        if newPos >= 0
            self.setPosition(newPos)
            @event = @events[@eventPosition]

            self.update

            skipButton.setEnabled(true)
        end

        backButton.setEnabled(false) if newPos == 0
    end

    def quit(sender)
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
            @settings.setInteger(1, :forKey => 'launchAtLoginState')
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
            @settings.setInteger(0, :forKey => 'launchAtLoginState')
        end
    end

end
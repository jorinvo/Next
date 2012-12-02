#
#  AppDelegate.rb
#  Next
#
#  Created by jorin vogel on 11/29/12.
#  Copyright 2012 jorin vogel. All rights reserved.
#

# TODO:
# * icon for app & notifications
# * option: open on startup


class AppDelegate
    attr_accessor :menu
    attr_accessor :eventName
    attr_accessor :backButton
    attr_accessor :skipButton

    def applicationDidFinishLaunching(a_notification)
        self.initMenu
        self.initCalendar
        self.initTimer
    end

    def initMenu
        menu.setAutoenablesItems(false)
        bar = NSStatusBar.systemStatusBar
        @item = bar.statusItemWithLength(NSVariableStatusItemLength)
        #TODO: use relative path
        @item.setImage(NSImage.alloc.initWithContentsOfFile("/Users/jorin/Dropbox/Projects/Next/Next/en.lproj/icon-small.png"))
        @item.setHighlightMode(true)
        @item.setMenu(menu)
        backButton.setEnabled(false)
        eventName.setEnabled(false)
    end

    def initCalendar
        @calendar = NSCalendar.currentCalendar
        @store = EKEventStore.alloc.initWithAccessToEntityTypes(EKEntityMaskEvent)

        NSNotificationCenter.defaultCenter.addObserver(
            self,
            :selector => "fetchEvents:",
            :name => EKEventStoreChangedNotification,
            :object => @store
        )

        self.fetchEvents
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
        @eventPosition = 0
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

    def fetchEvents(evt = nil)
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
        self.resetEvent

        self.update
    end
    #events

    def skip(sender)
        puts "DEBUG: skip"

        newPos = @eventPosition + 1
        len = @events.length

        if len >= newPos
            @eventPosition = newPos
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
            @eventPosition = newPos
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
end
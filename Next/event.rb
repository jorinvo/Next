require 'observer'
require 'settings'
require 'utils'


class Event
    include Observable

    def initialize
        load_calendar
        load
    end

    def title
        @current.title
    end

    def time
        time = @current.startDate.timeIntervalSinceNow
        if time < 60
            nil
        else
            humanize(time)
        end
    end

    def next?
        @all.length > @position
    end

    def previous?
        @position > 0
    end

    def next
        puts "DEBUG: select next event"

        @all.shift
        reset
        notify
    end


    def skip
        puts "DEBUG: skip"

        new_pos = @position + 1
        len = @all.length

        if len >= new_pos
            position = new_pos
            set_event

            notify

            true
        else
            false
        end
    end

    def back
        puts "DEBUG: back"

        new_pos = @position - 1

        if new_pos >= 0
            position = new_pos
            set_event

            notify

            true
        else
            false
        end
    end



    private


    def load
        fetch
        @position = Settings.position
        @current = @all[@position]
    end

    def load_calendar
        @calendar = NSCalendar.currentCalendar
        @store = EKEventStore.alloc.initWithAccessToEntityTypes(EKEntityMaskEvent)

        NSNotificationCenter.defaultCenter.addObserver(
                                                       self,
                                                       :selector => "update:",
                                                       :name => EKEventStoreChangedNotification,
                                                       :object => @store
                                                       )

    end

    def update(sender = nil)
        puts 'DEBUG: handle changes'

        fetch

        index = @all.index do |evt|
            evt.eventIdentifier == @current.eventIdentifier
        end
        reset if index  != @position

        notify
    end

    def fetch
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

        @all = @store.eventsMatchingPredicate(predicate)

        sort
    end

    def set_event
        @current = @all[@position]
    end

    def position=(pos)
        Settings.position = pos
        @position = pos
    end

    def sort
        @all.sort! do |e1, e2|
            startDate1 = e1.startDate.timeIntervalSinceNow
            startDate2 = e2.startDate.timeIntervalSinceNow
            (startDate1 < startDate2) ? -1 : 1
        end
    end

    def reset
        @current = @all.first
        position = 0
    end

    def notify
        changed
        notify_observers
    end

end
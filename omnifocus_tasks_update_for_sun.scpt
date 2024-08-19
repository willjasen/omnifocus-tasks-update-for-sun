-- Step 1: Get the sunset time using a shell command or external tool
set latitude to "36.320960"
set longitude to "-82.341760"
set timezone to "America/New_York"
set json to do shell script "curl -s 'https://api.sunrise-sunset.org/json?lat=" & latitude & "&lng=" & longitude & "&tzid=" & timezone & "&formatted=1'"
set sunset12hrTime to do shell script "echo " & quoted form of json & " | /usr/local/bin/python -c 'import sys, json; print(json.load(sys.stdin)[\"results\"][\"sunset\"][:19].replace(\"T\", \" \"))'"

-- display notification sunset12hrTime with title "Time of Sunset"

-- Step 2: Convert 12-hour time to 24-hour time
set sunset24hrTime to do shell script "date -j -f '%I:%M:%S %p' '" & sunset12hrTime & "' +'%H:%M:%S'"

-- Step 3: Create a date object for today with the sunset time
set sunsetDueTime to current date
set hours of sunsetDueTime to word 1 of sunset24hrTime
set minutes of sunsetDueTime to word 2 of sunset24hrTime
set seconds of sunsetDueTime to word 3 of sunset24hrTime

set theStartDate to current date
set hours of theStartDate to 0
set minutes of theStartDate to 0
set seconds of theStartDate to 0

set theEndDate to current date
set hours of theEndDate to 23
set minutes of theEndDate to 59
set seconds of theEndDate to 59

-- Step 4: Set the due date for the selected task in OmniFocus
tell application "OmniFocus"
    tell front document

        -- Get today and future tasks
        set task_elements to flattened tasks whose ¬
            (completed is false) and (due date is greater than or equal to theStartDate) and (due date is less than or equal to theEndDate)

        repeat with item_ref in task_elements

            set the_task to contents of item_ref
            set task_tags to tags of the_task
            set sunsetTagExists to false

            -- Check if the "🌅 Sunset" tag exists in the task's tags
            repeat with aTag in task_tags
                if name of aTag is "🌅 Sunset" then
                    set sunsetTagExists to true
                    exit repeat
                end if
            end repeat

            -- If the "🌅 Sunset" tag is found, update the due date
            if sunsetTagExists then
                set due date of the_task to sunsetDueTime
            end if

        end repeat

    end tell
end tell

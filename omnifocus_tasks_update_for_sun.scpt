-- This updates the task time but changes it to today, need to leave it the same date (or filter)

-- Step 1: Get the sunset time using a shell command or external tool
set json to do shell script "curl -s 'https://api.sunrise-sunset.org/json?lat=36.320960&lng=--82.341760&formatted=1'"
set sunsetTime to do shell script "echo " & quoted form of json & " | /usr/local/bin/python -c 'import sys, json; print(json.load(sys.stdin)[\"results\"][\"sunset\"][:19].replace(\"T\", \" \"))'"

-- Step 2: Convert 12-hour time to 24-hour time
set sunsetTimeParsed to do shell script "date -j -f '%I:%M:%S %p' '" & sunsetTime & "' +'%H:%M:%S'"

-- Step 3: Create a date object for today with the sunset time
set sunsetDueTime to current date
set hours of sunsetDueTime to word 1 of sunsetTimeParsed
set minutes of sunsetDueTime to word 2 of sunsetTimeParsed
set seconds of sunsetDueTime to word 3 of sunsetTimeParsed

set theStartDate to current date
set hours of theStartDate to 0
set minutes of theStartDate to 0
set seconds of theStartDate to 0

set theEndDate to current date
set hours of theEndDate to 23
set minutes of theEndDate to 59
set seconds of theEndDate to 59

-- Step 2: Set the due date for the selected task in OmniFocus
tell application "OmniFocus"
    tell front document

        -- Get today and future tasks with the sunset tag
        set task_elements to flattened tasks whose ¬
            (completed is false) and (due date is greater than or equal to theStartDate) and (due date is less than or equal to theEndDate) and (name of primary tag contains "🌅 Sunset")

        repeat with item_ref in task_elements

            set the_task to contents of item_ref

            -- Create a date object for the sunset time
            set task_due_time to sunsetDueTime

            -- Set the due date to the calculated sunset time
            set due date of the_task to task_due_time

        end repeat

    end tell
end tell

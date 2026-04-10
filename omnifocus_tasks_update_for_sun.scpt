log("Starting the OmniFocus sunset tasks script!")

-- Step 1: Read config
set configPath to (POSIX path of (path to me as text))
set configDir to do shell script "dirname " & quoted form of configPath
set configFile to configDir & "/config.json"
set latitude to do shell script "cat " & quoted form of configFile & " | grep -o '\"latitude\": *\"[^\"]*\"' | cut -d'\"' -f4"
set longitude to do shell script "cat " & quoted form of configFile & " | grep -o '\"longitude\": *\"[^\"]*\"' | cut -d'\"' -f4"
set timezone to do shell script "cat " & quoted form of configFile & " | grep -o '\"timezone\": *\"[^\"]*\"' | cut -d'\"' -f4"
set daysCount to (do shell script "cat " & quoted form of configFile & " | grep -o '\"days\": *[0-9]*' | grep -o '[0-9]*$'") as integer
log "Processing " & daysCount & " day(s): lat=" & latitude & " lng=" & longitude & " tz=" & timezone

set totalTasksUpdated to 0

-- Step 2: Loop over each day
repeat with dayOffset from 0 to daysCount - 1

    -- Get the date string for the API call (e.g. "2026-04-09")
    set targetDateString to do shell script "date -v+" & dayOffset & "d +'%Y-%m-%d'"

    -- Fetch sunset time for this specific date
    log "Fetching sunset for " & targetDateString
    set json to do shell script "curl -s 'https://api.sunrise-sunset.org/json?lat=" & latitude & "&lng=" & longitude & "&tzid=" & timezone & "&formatted=1&date=" & targetDateString & "'"
    set sunset12hrTime to do shell script "echo " & quoted form of json & " | grep -o '\"sunset\":\"[^\"]*\"' | cut -d'\"' -f4"
    log "Sunset (12hr) for " & targetDateString & ": " & sunset12hrTime

    -- Convert 12-hour time to 24-hour time
    set sunset24hrTime to do shell script "date -j -f '%I:%M:%S %p' '" & sunset12hrTime & "' +'%H:%M:%S'"

    -- Build midnight (start) of the target day
    set theStartDate to current date
    set hours of theStartDate to 0
    set minutes of theStartDate to 0
    set seconds of theStartDate to 0
    set theStartDate to theStartDate + (dayOffset * days)

    -- Build 23:59:59 (end) of the target day (fresh date object — never alias theStartDate)
    set theEndDate to current date
    set hours of theEndDate to 23
    set minutes of theEndDate to 59
    set seconds of theEndDate to 59
    set theEndDate to theEndDate + (dayOffset * days)

    -- Build the sunset due time for the target day (fresh date object)
    set sunsetDueTime to current date
    set hours of sunsetDueTime to 0
    set minutes of sunsetDueTime to 0
    set seconds of sunsetDueTime to 0
    set sunsetDueTime to sunsetDueTime + (dayOffset * days)
    set hours of sunsetDueTime to word 1 of sunset24hrTime
    set minutes of sunsetDueTime to word 2 of sunset24hrTime
    set seconds of sunsetDueTime to word 3 of sunset24hrTime

    -- Step 3: Update OmniFocus tasks for this day
    tell application "OmniFocus"
        tell front document

            set task_elements to flattened tasks whose ¬
                (completed is false) and ¬
                ((due date is greater than or equal to theStartDate and due date is less than or equal to theEndDate) or ¬
                 (planned date is greater than or equal to theStartDate and planned date is less than or equal to theEndDate))

            log "Tasks found to evaluate for " & targetDateString & ": " & (count of task_elements)

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

                -- If the "🌅 Sunset" tag is found, check the due date and planned date
                if sunsetTagExists then
                    log "Found sunset task: " & name of the_task
                    if due date of the_task is not missing value then
                        if due date of the_task is not sunsetDueTime then
                            log "Updating due date for: " & name of the_task
                            set due date of the_task to sunsetDueTime
                            set totalTasksUpdated to totalTasksUpdated + 1
                        else
                            log "Due date already correct for: " & name of the_task
                        end if
                    else
                        if planned date of the_task is not missing value then
                            if planned date of the_task is not sunsetDueTime then
                                log "Updating planned date for: " & name of the_task
                                set planned date of the_task to sunsetDueTime
                                set totalTasksUpdated to totalTasksUpdated + 1
                            else
                                log "Planned date already correct for: " & name of the_task
                            end if
                        end if
                    end if
                end if

            end repeat

        end tell
    end tell

end repeat

log "Total tasks updated: " & totalTasksUpdated
-- Notify user if tasks were updated
if totalTasksUpdated > 0 then
    display notification (totalTasksUpdated as text) & " task(s) updated with sunset time." with title "OmniFocus 🌅 Sunset Tasks"
end if

log("Stopped the OmniFocus sunset tasks script!")
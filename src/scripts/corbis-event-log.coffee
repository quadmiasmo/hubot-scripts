class EventLogHttp
    constructor: () ->
        @baseEndpoint = process.env.EVENTLOG_SERVICE_ENDPOINT

    callRestService: (msg, endpoint, callback) ->
        url = "#{@baseEndpoint}/#{endpoint}"
        msg.http(url)
            .header("Accept", "application/json")
            .get() (err, res, body) ->
                callback JSON.parse body

LogHttp = new EventLogHttp()
environments = [ "DEV", "SQA", "STG", "PROD" ]

module.exports = (robot) ->

    # Retrieves and displays details for a specific event log entry
    #
    # responds to:
    #   <robotName> corbis error me <guid> in <environment>
    #
    robot.respond /(corbis )?error(?: me| show)? "?([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})"?(?: (?:in|for|from|use) (dev|sqa|stg|prod|[a-z]+)\b)?( archives)?/i, (msg) ->
        validateRequest msg, (errorlog) ->
            msg.send "Calling service for event log. ActivityUid: #{errorlog.uid}, Environment: #{errorlog.env}...."
            displayErrorLog msg, errorlog

    # Retrieves and displays the top n most occurring error messages (with counts)
    #
    # responds to:
    #   <robotName> corbis errors show top <number> in <environment>
    #
    robot.respond /(corbis )?errors(?: me| show)?(?: (?:top )?(\d+))?(?: (?:in|for|from|use) (dev|sqa|stg|prod|[a-z]+)\b)?/i, (msg) ->
        validateRequest msg, (errorlog) ->
            count = if msg.match[2]? then msg.match[2] else 10
            msg.send "Calling service for the top #{count} error messages in #{errorlog.env}...."            
            displayTopErrorMessages msg, count, errorlog 

validateRequest = (msg, callback) ->
    log = new ErrorLog msg
    if log.env not in environments
        msg.send "#{log.env} is not a valid environment."
        return false

    callback log        

displayErrorLog = (msg, errorlog) ->
    endpoint = "ErrorLogDetails/#{errorlog.uid}/#{errorlog.env}"
    LogHttp.callRestService msg, endpoint, (json) ->
        errorlog.parseLog json
        msg.send errorlog.format()

displayTopErrorMessages = (msg, count, errorlog) ->
    endpoint = "TopErrors/#{count}/#{errorlog.env}"
    LogHttp.callRestService msg, endpoint, (json) ->
        formatted = [ "Top #{count} #{errorlog.brand} errors in #{errorlog.env}:\n" ]

        for m in json.Messages
            do (m) ->
                formatted.push("#{m.Key} (#{m.Value})")

        msg.send formatted.join("\n")                

class ErrorLog
    constructor: (msg) ->
        # parse matched chat room message values                  
        @msg      = msg
        @brand    = if msg.match[1]? then msg.match[1] else "Corbis"
        @uid      = msg.match[2]
        @env      = if msg.match[3]? then msg.match[3].toUpperCase() else "PROD"
        @archived = msg.match[4] isnt undefined
                          
        # properties to store values returned from rest calls
        @ActivityUid    = ""
        @HostName       = ""
        @LoggedAt       = ""
        @Message        = ""
        @StackTrace     = ""

        # an array of formatted display text for each property
        @propsDisplayText = []

    parseLog: (eventlog) ->
        props = []
        for prop, val of eventlog
            this[prop] = val
            @propsDisplayText.push("#{prop}: #{val}")

    format: ->
        return if @ActivityUid? then @propsDisplayText.join("\n\n") else @Message 

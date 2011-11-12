# Returns the full URL for the Corbis id provided.
#
# corbis (image) me <corbis_id>

module.exports = (robot) ->
  robot.respond /corbis(?: image)? me (.+)/i, (msg) ->
    corbis_id = msg.match[1]

    msg
      .http("http://www.corbisimages.com/stock-photo/#{corbis_id}")
      .get() (err, res, body) ->
        if res.statusCode is 301
          msg.send "http://www.corbisimages.com#{res.headers.location}"
        else
          msg.send "Not found"

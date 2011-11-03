reason = [
 "I'm sorry Dave, I'm afraid I can't do that."
,"You don't pay me enough."
,"Put it on the list."]
module.exports = (robot) ->
 robot.respond /can you/, (msg) ->
  msg.send msg.random reason

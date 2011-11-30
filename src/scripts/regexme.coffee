# Runs a regular expression against an input string
#
# regex me "<input_string>" with <regex>
    
regitup = (match) ->

    input = match[1]
    pattern = match[2]

    if input is "recursion"
        return "Did you mean: #{match.input}?"

    matches = exec input, pattern

    if matches is null
        return "The pattern did not match the input string. Perhaps a trip to http://regular-expression.info is in order. Or maybe the regexes used in this script would more benefit from that trip."
    else
        return format matches

exec = (input, pattern) ->
    regParts = pattern.match(/^\/?([^$]+?)\/?([gim]{0,3})$/)
    # [1] regex pattern [2] modifiers (if any, /<pattern>/ig)
    reg = new RegExp(regParts[1], regParts[2])
    return input.match(reg)

format = (matches) ->
    output = []
    output.push("Match(es):")

    for m in matches
        do (m) ->
            output.push("    #{m}")

    return output.join("\n")

module.exports = (robot) ->
    robot.respond /regex(?: me)? "([^\\"]+)" (?:(?:using|with) )?([^$]+)$/i, (msg) ->
        msg.send regitup msg.match

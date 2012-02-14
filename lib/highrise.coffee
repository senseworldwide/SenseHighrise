#   Highrise api wrapper
#
#   Philip Cole <philip@pcole.me>
#
#   Only supports People GET/POST/PUT & Tag POST
#   TODO: Tests!

rest    = require 'restler'
jsonxml = require 'jsontoxml'
xml2js  = require 'xml2js'
_s      = require 'underscore.string'

#   Modify restlers xml parser to ignore any attributes
#   by injecting the option "ignoreAttrs" during the xml2js parser
#   instanciation
rest.parsers.auto.matchers['application/xml'] = (data, callback) ->
    if data
        parser = new xml2js.Parser {ignoreAttrs: true}
        parser.on 'end', (result) -> callback result
        try
            parser.parseString data
        catch e
            callback {error:'Oops, something went wrong.'}
    else callback()

#   Escapes all string properties in an object
escapeStrings = (obj) ->
    if typeof obj is "array"
        obj = obj.reduce((hash,member) ->
            hash[member.substr(0)] = {val:member}
            hash
        ,{})
    for own k, v of obj
        do (k,v) ->
            type = typeof v
            switch type
                when "string"
                    obj[k] = _s.escapeHTML v
                when "object", "array"
                    obj[k] = escapeStrings v
    return obj

class Highrise

    constructor: (user, password, host) ->
        @baseURL = "https://#{user}:#{password}@#{host}"

    getPerson: (id, callback) ->
        req = rest.get "#{@baseURL}/people/#{id}.xml"
        req.on 'complete', (data, response) ->
            callback data, response.statusCode, response

    createPerson: (person, callback) ->
        person = escapeStrings person
        personXml = jsonxml.obj_to_xml person
        rest.post("#{@baseURL}/people.xml",
            data: personXml
            headers: {'Content-type':'application/xml'}
        ).on 'complete',  (data, response) ->
            callback data, response.statusCode, response
    
    updatePerson: (id, person, callback) ->
        person = escapeStrings person
        personXml = jsonxml.obj_to_xml person
        rest.put("#{@baseURL}/people/#{id}.xml", {
            data: personXml
            headers: {'Content-type':'application/xml'}
        }).on 'complete',  (data, response) ->
            callback data, response.statusCode, response

    tagPerson: (personId, tag, callback) ->
        rest.post("#{@baseURL}/people/#{personId}/tags.xml",
            data: "<name>#{tag}</name>"
            headers: {'Content-type':'application/xml'}
        ).on 'complete',  (data, response) ->
            callback data, response.statusCode, response

module.exports = Highrise

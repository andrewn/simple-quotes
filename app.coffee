
express = require('express')
request = require('request')

app = express.createServer()

EMAIL       = process.env.QUOTE_EMAIL
PASSWORD    = process.env.QUOTE_PASSWORD
QUOTE_TAG   = "quote"

unless EMAIL? and PASSWORD?
    console.log("Need email and password")
    process.exit() 

console.log("*" + EMAIL + "*")
console.log("*" + PASSWORD + "*")

randomise = ->
   (Math.round(Math.random())-0.5)

# Routes
app.get '/quotes', (req, res, next) ->
  sendQuotes = (quotes) ->
    res.send JSON.stringify quotes
  sn.findNotesByTag(QUOTE_TAG, sendQuotes)

# ALT: app.get '/quotes/random.:format?', middleWareHere, (req, res, next) ->
app.get '/quotes/random.:format?', (req, res, next) ->
  pickRandomQuote = (quotes) ->
    quotes.sort(randomise)
    quote = quotes[0]
    sn.findNote(quote.key, sendQuote)

  sendQuote = (quote) -> 
    res.send JSON.stringify quote if req.params.format == "json"
    res.send "<h1>#{quote.content}</h1>"

  sn.findNotesByTag(QUOTE_TAG, pickRandomQuote)

# Startup
app.listen 3000
console.log 'Express app started on port 3000'

# Simplenote API connector
class Simplenote
    apiBaseSecure  : "https://simple-note.appspot.com"
    apiBase  : "http://simple-note.appspot.com" 
    loggedIn : false
    auth     : null

    constructor: (@username, @password) ->
        this.login()
    
    findNote: (key, callback) ->
        this.login() unless this.auth
        apiUrl = "#{this.apiBase}/api2/data/#{key}?auth=#{this.auth}&email=#{EMAIL}"
        foundNote = (body) ->
            callback(body)
        this.request(apiUrl, foundNote)

    findNotesByTag: (tag, callback) ->
        this.login() unless this.auth
        apiUrl = "#{this.apiBase}/api2/index?length=100&auth=#{this.auth}&email=#{EMAIL}"
        console.log(apiUrl)
        hasTag = (tagToFind, set) ->
            found = (tag for tag in set when tag == tagToFind)
            found.length > 0
        filterTagsAndRespond = (body) ->
            quotes = (item for item in body.data when hasTag(QUOTE_TAG, item.tags))
            callback(quotes)
        this.request(apiUrl, filterTagsAndRespond)
    
    login: (callback) -> 
        apiUrl = "#{this.apiBaseSecure}/api/login"
        console.log "Login #{apiUrl}"
        emailPass = "email=#{EMAIL}&password=#{PASSWORD}"
        encodedEmailPass = new Buffer(emailPass).toString('base64')
        authCallback = (body, res) =>
            this.auth = body
            callback() if callback
        this.request(apiUrl, authCallback, 'POST', encodedEmailPass)

    request: (uri, callback, method='GET', data=null) ->
        options = 
            uri: uri
            method: method  
            body: data
        request options, (err, res, body) -> 
            console.log(res.statusCode, body[0...90], '...')
            try
                body = JSON.parse body
            catch error
                
            callback(body, res)

# 
sn = new Simplenote(EMAIL, PASSWORD)

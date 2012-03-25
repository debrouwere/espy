_ = require 'underscore'
fs = require 'fs'
fs.path = require 'path'
async = require 'async'
parsers = require './parsers'

name = (file) ->
    extlen = -(fs.path.extname file).length
    (fs.path.basename file).slice(0, extlen)

getDataDir = (template, src) ->
    dir = fs.path.dirname template
    fs.path.join dir, src

# find data files for a template file and return them in order (latest changed first)
exports.findFilesFor = (template, src='data', callback) ->
    src = getDataDir template, src
    fs.readdir src, (errors, files) ->
        files = files
            .filter (file) ->
                # TODO: a better way to get supported formats
                # (data-centric ones like json, yaml and txt + compilers flagged as 
                # markup languages in the handlers?)
                # SEE parsers.coffee
                (fs.path.extname file) in ['.yaml', '.yml', '.json', '.txt']
            .map (file) ->
                fs.path.join src, file

        callback files

# find context sets for a data file and return them in a hash
exports.findSetsFor = (template, src='data', callback) ->
    dataDir = getDataDir template, src
    setDir = fs.path.join dataDir, name template
    fs.path.exists setDir, (exists) ->
        if exists
            exports.findFilesFor '/', setDir, callback
        else
            callback []

exports.getDocument = (file, callback) ->
    ext = (fs.path.extname file)

    fs.readFile file, 'utf8', (errors, str) ->
        if errors then new Error "Couldn't get document"

        # TODO: a better way to get all markup languages (because those are
        # the only ones that can be prefaced with frontmatter)
        # SEE parsers.coffee
        if ext in ['.yaml', '.yml', '.txt', '.md', '.markdown']
            doc = YAML.parse str
            if doc instanceof String
                callback {meta: {}, body: doc}
            else
                callback {meta: doc[0], body: doc[1]}
        else if ext is '.json'
            callback JSON.parse str

exports.parse = (file, callback) ->
    exports.getDocument file, (document) ->
        context = {}
        context[name file] = document
        callback null, context

        ###
        SEE NOTES ABOVE
        handlers.compile (handlers.File path: file, content: body), undefined, (body) ->    
        ###

getContext = (files, callback) ->
    async.map files.reverse(), exports.parse, (errors, context) ->
        # merge different context objects together
        context = _.extend {}, context...
        callback context

# find context for a template file
# TODO: make asynchronous
exports.findFor = ->
    if arguments.length is 3
        [template, src, callback] = arguments
    else if arguments.length is 2
        src = 'data'
        [template, callback] = arguments
    else
        throw new Error "Wrong arguments for Registry#findFor."

    exports.findSetsFor template, src, (files) ->
        getContext files, (sets) ->
            setContext = {}
            setContext[name template] = sets
            exports.findFilesFor template, src, (files) ->
                getContext files, (context) ->
                    mergedContext = _.extend {}, setContext, context
                    contextWithShortcuts = _.extend {data: mergedContext}, mergedContext[name template]
                    callback contextWithShortcuts

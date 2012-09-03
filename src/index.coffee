_ = require 'underscore'
fs = require 'fs'
fs.path = require 'path'
async = require 'async'
tilt = require 'tilt'
parsers = require './parsers'

name = (file) ->
    extlen = -(fs.path.extname file).length
    (fs.path.basename file).slice(0, extlen)

getDataDir = (template, src) ->
    if (fs.path.extname template).length
        dir = fs.path.dirname template
    else
        dir = template
    fs.path.join dir, src

# find data files for a template file and return them in order (latest changed first)
exports.findFilesFor = (template, src='data', callback) ->
    src = getDataDir template, src

    fs.readdir src, (errors, files) ->
        # we soak up errors because it's perfectly normal (and not an error condition)
        # for a template not to have any associated data files
        if errors? then files = []

        files = files
            .filter (file) ->
                # TODO: a better way to get supported formats
                # (data-centric ones like json, yaml and txt + compilers flagged as 
                # markup languages in the handlers?)
                # SEE parsers.coffee
                (fs.path.extname file) in ['.yaml', '.yml', '.json', '.txt', '.md']
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

exports.parse = (file, callback) ->
    doc = new tilt.File path: file
    tilt.parse doc, null, (errors, data) ->
        if errors then return callback errors

        if data.meta then data.meta.origin = {filename: file}
        context = {}
        context[name file] = data
        callback null, context

getContext = exports.getContext = (files, callback) ->
    async.map files.reverse(), exports.parse, (errors, context) ->
        # merge different context objects together
        context = _.extend {}, context...
        callback errors, context

# find context for a template file
exports.findFor = ->
    if arguments.length is 3
        [template, src, callback] = arguments
    else if arguments.length is 2
        src = 'data'
        [template, callback] = arguments
    else
        throw new Error "Wrong arguments for Registry#findFor."

    # find context sets
    exports.findSetsFor template, src, (files) ->
        getContext files, (errors, sets) ->
            setContext = {}
            setContext[name template] = sets
            # find individual context files
            exports.findFilesFor template, src, (files) ->
                getContext files, (context) ->
                    mergedContext = _.extend {}, setContext, context
                    contextWithShortcuts = _.extend {data: mergedContext}, mergedContext[name template]
                    callback contextWithShortcuts
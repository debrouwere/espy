_ = require 'underscore'
fs = require 'fs'
fs.path = require 'path'
fs.findit = require 'findit'
async = require 'async'
tilt = require 'tilt'

name = (file) ->
    extlen = -(fs.path.extname file).length
    (fs.path.basename file).slice(0, extlen)

getDataDir = (template, src) ->
    if (fs.path.extname template).length
        dir = fs.path.dirname template
    else
        dir = template
    fs.path.join dir, src

filterFiles = (src, callback) ->
    (errors, files) ->
        # we soak up errors because it's perfectly normal (and not an error condition)
        # for a template not to have any associated data files
        if errors? then files = []

        files = files
            .filter (file) ->
                hidden = (file.indexOf '/.') isnt -1
                if hidden
                    return no
                else
                    return tilt.hasHandler new tilt.File path: file
            .map (file) ->
                fs.path.resolve src, file

        callback files

# find data files for a template file and return them in order (latest changed first)
# TODO: 
exports.findFilesFor = (template, src='data', recursive..., callback) ->
    src = getDataDir template, src
    recursive = if recursive?[0] is yes then yes else no
    filter = filterFiles src, callback

    if recursive
        finder = fs.findit.find src
        files = []
        finder.on 'file', (file, stat) -> files.push file
        finder.on 'end', -> filter null, files
    else
        fs.readdir src, filter

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
    tilt.parse file, null, (errors, data) ->
        if errors then return callback errors
        if data.meta then data.meta.origin = {filename: file}
        context = {}
        # TODO: regardless of whether findFilesFor is/has been recursive, 
        # `name file` should make a name relative to the base dir, never 
        # just take the filename sans extension (which is unfortunately
        # what it does now).
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
        src = 'fixtures'
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
                getContext files, (errors, context) ->
                    mergedContext = _.extend {}, setContext, context
                    contextWithShortcuts = _.extend {data: mergedContext}, mergedContext[name template]
                    callback contextWithShortcuts
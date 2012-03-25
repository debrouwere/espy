context = require '../src'
should = require 'should'
fs = {path: require 'path'}

index = fs.path.join __dirname, 'fixtures/index.jade'
brochure = fs.path.join __dirname, 'fixtures/brochure.html'

it 'can find context related to a template', (done) ->
    context.findFor index, (c) ->
        c.data.index.title.should.equal 'Hello world'
        done()

it 'can create shortcuts for context in files that have the same basename as the template', (done) ->
    context.findFor index, (c) ->
        c.data.index.title.should.equal c.title
        done()

it 'can find context sets related to a template', (done) ->
    context.findSetsFor brochure, 'data', (files) ->
        files.length.should.equal 3
        done()

it 'can process context sets related to a template', (done) ->
    context.findFor brochure, (c) ->
        c.data.brochure.dark.background.should.equal '333'
        c.data.brochure.light.background.should.equal 'eee'
        c.dark.background.should.equal c.data.brochure.dark.background
        done()

it 'merges conflicting context on a newest-stays basis'

it 'can process multi-document YAML files'

it 'can work with custom search paths: a file'

it 'can work with custom search paths: a directory'

it 'can work with custom search paths: a regex'

# Espy

Espy is a context finder for templates. Context finders pass values to your templates not from a database like most web applications would, but by searching for JSON and other data files in predefined locations.

Context finding is useful for two particular use-cases: 

* **static site generation**: all pages or blogposts, metadata and configuration reside in flat files, and you want to render that information to pages using your favorite template language
* **prototyping**: you eventually want to hook up your front-end prototype to a proper back-end, but just to get started it'd be useful to pass on some dummy data to your templates without having to run a database or create a project in Rails, Django, Express or what-have-you

For example, the [Jekyll](https://github.com/mojombo/jekyll) blog engine will automatically make all your blog posts and other metadata available to your blog its templates under `page`, `post` and `content`. And [Middleman](http://middlemanapp.com), a static site generator, looks for YAML data in a `/data` subdirectory and passes that on to templates.

Espy helps you implement similar functionality in your own applications.

## Status

Espy is **no longer actively maintained**.

For generating templates using context data, try out the [Render](https://github.com/stdbrouw/render) command-line utility instead. Together with the [Serve](https://github.com/stdbrouw/serve) live reloading server it makes for a great prototyping environment.

If you're interested in a tool that can help you parse YAML multidocs (combinations of YAML frontmatter and Markdown content), check out my take on what a proper multidoc parser looks like: [yaml2json](https://github.com/stdbrouw/yaml2json). Together with [Render](https://github.com/stdbrouw/render), you've got yourself a full-blown static site generator.

Another option for quick prototyping using context data is [Middleman](http://middlemanapp.com/guides/local-yaml-data), which was an inspiration in creating Espy.

## Example

Here's an example, using [Tilt.js](https://github.com/stdbrouw/tilt.js) to render the templates: 

    /* data/homepage.json */
    {
        "title": "Hello world"
    }

    /* homepage.jade */
    !!! 5
    html
        head
            title= title

    /* app.js */
    var context = require('espy');
    var tilt = require('tilt');
    var src = 'homepage.jade';
    var dest = 'homepage.html';
    
    context.findFor(src, function(context) {
        console.log(context.data.homepage.title === context.title === 'Hello world');
        tilt.compile(src, context, function(errors, html) {
            fs.writeFile dest, 'utf8'
        });
    });

## Installation

Install with `npm install espy`.

## Conventions (mostly implemented)

By default, Tilt.js its context finder works with conventions that extend but are very similar to those [Middleman](http://middlemanapp.com/guides/local-yaml-data) uses for local YAML data, with a couple of added features.

Data is read from YAML, JSON, CSV and XML files in a `data` directory underneath the directory where your template resides. (CSV and XML support pending.)

`tilt.context.findFor` returns the data it found as a context hash. Data is available under the `data` key in the resulting context hash.

### Conflict resolution

Context from `/data/test.json` will be available under `data.test`. If multiple data files are named "test" (e.g. `test.json` and `test.yml` then Tilt will merge the resulting context hashes, and resolve conflicting keys (for example if you specify a title in both the JSON and the YAML file) by picking the value from the last updated (newest) file.

Please note that Espy doesn't do a full recursive merge. If you define `title` in one context file and `body` in another, those will be merged. But if you define `author.name` in one context file and `author.email` in another, you'll end up with just one of both values in the resulting context object.

### Shortcuts

While all context from a data directory is available under the `data` key, the context hash will also contain some shortcuts to data that's (likely to be) specific to a template or page. So if you're rendering index.haml, the `title` context value from an index.json file will be available under `data.index.title` but will also be expanded into the main namespace as just `title`.

### Context sets

Lastly, the context finder expands on Middleman's conventions through context sets. (Pending.) If you have subdirectories inside of your `/data` directory, Tilt will process those as `/data/<template>/<contextset>.json`. For a template called `homepage.dtl` and a data file that lives at `/data/homepage/alt.json`, the resulting `data` object will look like this:
  
    {
        "homepage": {
            "alt": {
                "key": "val"
            }
        }
    }

This is useful as a basic building block for applications that need to render the same template many times with different data, for example blogposts that all use the same template or a design prototype that you want to have a couple of variations of.

Note that, if you have an individual context file, e.g. `data/design.json`, in addition to context sets in `data/design`, the individual context file's data will override data in the `data/design/design.json` set. For your own sanity, don't use context sets and individual context files together for a single template.

### Using YAML files

YAML data files work a little bit differently from JSON and CSV. With YAML, your file can contain both data (often called "front matter") and free-form text in separate YAML documents, for example metadata for a blogpost and then the post itself. Documents in a YAML file are separated by a string of three dashes and a newline (`---`).

Here's an example of a YAML file with front matter and body documents: 

    ---
    type: quote
    language: en
    title: Eye-opening
    author: Emily Bell
    ---

    The opening of electronic ears and eyes is not a replacement for reporting. It should be at the heart of it.

The context finder can also parse YAML front matter inside of Markdown (`.md`) and Textile (`.textile`) files, which is very helpful when you're building a blog engine or static site generator.

Data from YAML files is under the `data` key in the context hash just like it would be for JSON or CSV. Front matter (the first YAML document) is under `data.meta` and free-form text (the second YAML document) is under `data.body`.

### Using XML (soon)

Tilt.js has basic XML support. Anything that can be unambigously translated into JSON will work. Attributes or text nodes will be ignored.

This XML

    <root>
        <title for="document">Hello world</title>
        <authors>
            These are the authors: 
            <author>John</author>
            <author>Beth</author>            
    </root>

will result in this context object

    {
        "title": "Hello world", 
        "authors": [
            {"author": "John"},
            {"author": "Beth"}
        ]
    }

## Customization (soon)

The directory or file Espy searches for context is customizable. You can change the default dir from `data` to something else, you can specify a regex files should match (e.g. prefixed with an underscore), or you can just specify that all context should come from e.g. `data.json` in the current directory.

Note that, because finding context and rendering templates are separate, your application can use and modify the context hash returned by the context finder however you want it to before passing on the context to the template compiler of your choice.

    TODO: example

For example, you could make only a subset of the data available to the template. You could also loop over arrays in a context hash and render a separate page for each item.

    TODO: example

## Related projects

Espy was originally extracted from the [Tilt.js](https://github.com/stdbrouw/tilt.js) template compiler, which provides a generic interface to many different template languages, and Espy and Tilt.js still work really well together.

Espy is used in the [Draughtsman](https://github.com/stdbrouw/draughtsman) front-end prototyping server. It's also used in [Hector](https://github.com/stdbrouw/hector), a static site generator.

{View} = require 'atom'
Highlights = require 'highlights'

class DiffDetailsView extends View
  @content: ->
    @div class: "diff-details-outer", outlet: "container", =>
      @div class: "diff-details", outlet: "mainPanel", =>
        @div class: "diff-details-overlay"
        @div outlet: "contents"
      @div outlet: "buttonPanel", class: "diff-details-button-panel", =>
        @button click: "doCopy", class: 'btn btn-primary inline-block-tight', 'Copy'
        @button click: "doUndo", class: 'btn btn-error inline-block-tight', 'Undo'

  initialize: (@editorView) ->
    {@editor} = @editorView
    @attach()
    @highlighter = new Highlights()

    # Prevent focusout event
    @buttonPanel.on 'mousedown', () ->
      false

    @mainPanel.on 'mousedown', () ->
      false

  attach: ->
    @editorView.appendToLinesView(this)

  setPosition: (top) ->
    {left, top} = @editorView.pixelPositionForBufferPosition(row: top - 1, col: 0)
    @css(top: top + @editorView.lineHeight)

  setSelectedHunk: (@selectedHunk) ->

    @str = ""
    for hunkDetail in @selectedHunk.oldLines
      # TODO \n needs to be replaced with &nbsp; if its an empty line
      @str += "#{hunkDetail}"

    htmlStr = @highlighter.highlightSync
      fileContents: @str
      scopeName: 'source.coffee'

    htmlStr = htmlStr.replace('<pre class="editor editor-colors">', '').replace('</pre>', '')

    @contents.css(height: @selectedHunk.oldLines.length * @editorView.lineHeight)

    @contents.html(htmlStr)

  doCopy: (e) ->
    console.log "copy"

  doUndo: (e) ->
    if buffer = @editor.getBuffer()
      if @selectedHunk.kind is "m"
        buffer.deleteRows(@selectedHunk.start - 1, @selectedHunk.end - 1)
        buffer.insert([@selectedHunk.start - 1, 0], @str)
      else
        buffer.insert([@selectedHunk.start, 0], @str)

module.exports = DiffDetailsView

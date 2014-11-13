{View} = require 'atom'
Highlights = require 'highlights'

class DiffDetailsView extends View
  @content: ->
    @div class: "diff-details-outer", =>
      @div class: "diff-details-main-panel", outlet: "mainPanel", =>
        @div class: "diff-details-main-panel-contents", outlet: "contents"
      @div class: "diff-details-button-panel", outlet: "buttonPanel", =>
        @button class: 'btn btn-primary inline-block-tight', click: "copy", 'Copy'
        @button class: 'btn btn-error inline-block-tight', click: "undo", 'Undo'

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
      @str += "#{hunkDetail}"

    htmlStr = @highlighter.highlightSync
      fileContents: @str
      scopeName: 'source.coffee'

    htmlStr = htmlStr.replace('<pre class="editor editor-colors">', '').replace('</pre>', '')

    @contents.css(height: @selectedHunk.oldLines.length * @editorView.lineHeight)

    @contents.html(htmlStr)

  copy: (e) ->
    console.log "copy"

  undo: (e) ->
    if buffer = @editor.getBuffer()
      if @selectedHunk.kind is "m"
        buffer.deleteRows(@selectedHunk.start - 1, @selectedHunk.end - 1)
        buffer.insert([@selectedHunk.start - 1, 0], @str)
      else
        buffer.insert([@selectedHunk.start, 0], @str)

module.exports = DiffDetailsView

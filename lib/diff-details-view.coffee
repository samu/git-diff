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
    html = @highlighter.highlightSync
      fileContents: @selectedHunk.oldString
      scopeName: 'source.coffee'

    html = html.replace('<pre class="editor editor-colors">', '').replace('</pre>', '')
    @contents.html(html)
    @contents.css(height: @selectedHunk.oldLines.length * @editorView.lineHeight)

  copy: (e) ->
    console.log "copy"

  undo: (e) ->
    if buffer = @editor.getBuffer()
      if @selectedHunk.kind is "m"
        buffer.deleteRows(@selectedHunk.start - 1, @selectedHunk.end - 1)
        buffer.insert([@selectedHunk.start - 1, 0], @selectedHunk.oldString)
      else
        buffer.insert([@selectedHunk.start, 0], @selectedHunk.oldString)

module.exports = DiffDetailsView

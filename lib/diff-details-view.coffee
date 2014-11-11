{View} = require 'atom'
Highlights = require 'highlights'

class DiffDetailsView extends View
  @content: ->
    @div class: "diff-details-outer", =>
      @div class: "diff-details editor", =>
        @div class: "diff-details-overlay"
        @div outlet: "contents"

  initialize: (@editorView) ->
    {@editor} = @editorView
    @attach()
    @highlighter = new Highlights()

  attach: ->
    @editorView.appendToLinesView(this)

  setPosition: (top) ->
    {left, top} = @editorView.pixelPositionForBufferPosition(row: top - 1, col: 0)
    @css(top: top + @editorView.lineHeight)

  setHunkDetails: (hunkDetails) ->
    str = ""
    for hunkDetail in hunkDetails
      # TODO \n needs to be replaced with &nbsp; if its an empty line
      str += "#{hunkDetail}"

    str = @highlighter.highlightSync
      fileContents: str
      scopeName: 'source.coffee'

    str = str.replace('<pre class="editor editor-colors">', '').replace('</pre>', '')

    # @css(height: hunkDetails.length * @editorView.lineHeight + 42)
    @css(height: hunkDetails.length * @editorView.lineHeight + 2)

    # str = "<atom-text-editor></atom-text-editor>"

    @contents.append(str)

module.exports = DiffDetailsView

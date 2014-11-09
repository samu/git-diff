{View} = require 'atom'

class DiffDetailsView extends View
  @content: ->
    @div class: "diff-details", =>
      @div =>
        @text "bla blabla"
      @div =>
        @text "bla blabla"

  initialize: (@editorView) ->
    {@editor} = @editorView

    @attach()

  attach: ->
    @editorView.appendToLinesView(this)

  setPosition: (top)->
    {left, top} = @editorView.pixelPositionForBufferPosition(row: top, col: 0)
    @css(top: top + @editorView.lineHeight)

module.exports = DiffDetailsView

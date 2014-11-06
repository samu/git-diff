{View} = require 'atom'

class DiffDetails extends View
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
    @setPosition()

  setPosition: ->
    pos = @editor.getCursorScreenPosition()
    pos.row += 1
    {left, top} = @editorView.pixelPositionForScreenPosition(pos)

    @css(top: top)

module.exports = DiffDetails

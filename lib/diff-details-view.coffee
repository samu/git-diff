{View} = require 'atom'
DiffDetailsDataManager = require './diff-details-data-manager'
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
    @highlighter = new Highlights()

    # Prevent focusout event
    @buttonPanel.on 'mousedown', () ->
      false

    @mainPanel.on 'mousedown', () ->
      false

    @buffer = @editor.getBuffer()

    @diffDetailsDataManager = new DiffDetailsDataManager()
    @showDiffDetails = false
    @lineDiffDetails = null

    @updateCurrentRow()
    @initializeSubscriptions()

    @subscribeToCommand @editorView, 'git-diff:toggle-diff-details', =>
      @toggleShowDiffDetails()

    # @attach()

  initializeSubscriptions: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
      @notifyChangeCursorPosition()

  notifyChangeCursorPosition: ->
    if @showDiffDetails
      currentRowChanged = @updateCurrentRow()
      @updateDiffDetailsDisplay() if currentRowChanged

  attach: ->
    @editorView.appendToLinesView(this)

  setPosition: (top) ->
    {left, top} = @editorView.pixelPositionForBufferPosition(row: top - 1, col: 0)
    @css(top: top + @editorView.lineHeight)

  populate: (selectedHunk) ->
    html = @highlighter.highlightSync
      fileContents: selectedHunk.oldString
      scopeName: 'source.coffee'

    html = html.replace('<pre class="editor editor-colors">', '').replace('</pre>', '')
    @contents.html(html)
    @contents.css(height: selectedHunk.oldLines.length * @editorView.lineHeight)

  copy: (e) ->
    console.log "copy"

  undo: (e) ->
    selectedHunk = @diffDetailsDataManager.getSelectedHunk(@currentRow)

    if buffer = @editor.getBuffer()
      if selectedHunk.kind is "m"
        buffer.deleteRows(selectedHunk.start - 1, selectedHunk.end - 1)
        buffer.insert([selectedHunk.start - 1, 0], selectedHunk.oldString)
      else
        buffer.insert([selectedHunk.start, 0], selectedHunk.oldString)

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updateDiffDetailsDisplay: ->
    if @showDiffDetails
      selectedHunk = @diffDetailsDataManager.getSelectedHunk(@currentRow)

      if selectedHunk?
        @attach()
        @setPosition(selectedHunk.end)
        @populate(selectedHunk)
        return

    @detach()
    return

  updateCurrentRow: ->
    newCurrentRow = @getActiveTextEditor()?.getCursorBufferPosition()?.row + 1
    if newCurrentRow != @currentRow
      @currentRow = newCurrentRow
      return true
    return false

  removeSubscriptions: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = null

  toggleShowDiffDetails: ->
    @showDiffDetails = !@showDiffDetails
    @updateCurrentRow()
    @updateDiffDetailsDisplay()

  notifyContentsModified: ->
    @diffDetailsDataManager.invalidate(atom.project.getRepo(),
                                       @buffer.getPath(),
                                       @buffer.getText())
    if @showDiffDetails
      @updateDiffDetailsDisplay()

module.exports = DiffDetailsView

DiffDetailsView = require './diff-details-view'
DiffDetailsDataManager = require './diff-details-data-manager'
{Subscriber} = require 'emissary'

module.exports = class DiffDetailsHandler
  Subscriber.includeInto(this)

  constructor: (@editorView) ->
    {@editor} = @editorView
    @buffer = @editor.getBuffer()

    @diffDetailsDataManager = new DiffDetailsDataManager()
    @showDiffDetails = false
    @lineDiffDetails = null

    @updateCurrentRow()
    @initializeSubscriptions()

    @subscribeToCommand @editorView, 'git-diff:toggle-diff-details', =>
      @toggleShowDiffDetails()

  initializeSubscriptions: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
      @notifyChangeCursorPosition()

  notifyChangeCursorPosition: ->
    if @showDiffDetails
      currentRowChanged = @updateCurrentRow()
      @updateDiffDetailsDisplay() if currentRowChanged

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updateDiffDetailsDisplay: ->
    if @showDiffDetails
      selectedHunk = @diffDetailsDataManager.getSelectedHunk(@currentRow)

      if selectedHunk?
        @diffDetailsView = new DiffDetailsView(@editorView) unless @diffDetailsView?
        @diffDetailsView.setPosition(selectedHunk.end)
        @diffDetailsView.setSelectedHunk(selectedHunk)
        return

    @diffDetailsView.remove() if @diffDetailsView?
    @diffDetailsView = null
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
    repo = atom.project.getRepo()
    path = @buffer?.getPath()
    text = @buffer.getText()
    @diffDetailsDataManager.invalidate(repo, path, text)
    if @showDiffDetails
      @updateDiffDetailsDisplay()

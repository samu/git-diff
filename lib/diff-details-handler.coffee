DiffDetailsView = require './diff-details-view'
{Subscriber} = require 'emissary'

module.exports = class DiffDetailsHandler
  Subscriber.includeInto(this)

  constructor: (@editorView) ->
    {@editor} = @editorView
    @showDiffDetails = true
    @subscribeToCommand @editorView, 'git-diff:toggle-diff-details', =>
      @toggleShowDiffDetails()

    @subscribeToActiveTextEditor()

  subscribeToActiveTextEditor: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
      @updateCurrentRow()
    @updateCurrentRow()

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updateCurrentRow: ->
    newCurrentRow = @getActiveTextEditor()?.getCursorBufferPosition()?.row + 1
    if newCurrentRow != @currentRow
      @currentRow = newCurrentRow
      hunkHasChanged = @updateSelectedHunk()
      @updateDiffDetailsDisplay() if hunkHasChanged

  toggleShowDiffDetails: ->
    @showDiffDetails = !@showDiffDetails
    @updateDiffDetailsDisplay()

  liesBetween: (hunk, row) ->
    hunk.start <= row <= hunk.end

  updateSelectedHunk: ->
    if @selectedHunk
      return false if @liesBetween(@selectedHunk, @currentRow)

    @selectedHunk = null

    if @lineDiffDetails?
      for hunk in @lineDiffDetails
        if @liesBetween(hunk, @currentRow)
          @selectedHunk = hunk
          break

    return true

  updateDiffDetailsDisplay: ->
    if @selectedHunk? and @showDiffDetails
      @diffDetailsView = new DiffDetailsView(@editorView) unless @diffDetailsView?
      @diffDetailsView.setPosition(@selectedHunk.end)
      @diffDetailsView.setHunkDetails(@selectedHunk.oldLines)
    else
      @diffDetailsView.remove() if @diffDetailsView?
      @diffDetailsView = null

  prepareLineDiffDetails: (rawDiffDetails) ->
    @lineDiffDetails = []
    hunk = null

    for {oldStart, newStart, oldLines, newLines, oldLineNo, newLineNo, line} in rawDiffDetails
      unless oldLines is 0 and newLines > 0
        newEnd = null
        if newLines is 0 and oldLines > 0
          newEnd = newStart
        else
          newEnd = newStart + newLines - 1

        if not hunk? or (newStart != hunk.start)
          hunk = {start: newStart, end: newEnd, oldLines: [], newLines: []}
          @lineDiffDetails.push(hunk)

        if newLineNo >= 0
          hunk.newLines.push(line)
        else
          hunk.oldLines.push(line)

  notifyContentsModified: (diffs, buffer) ->
    @selectedHunk = null

    if path = buffer?.getPath()
      lineDiffDetails = atom.project.getRepo()?.getLineDiffDetails?(path, buffer.getText())
      if lineDiffDetails?
        @prepareLineDiffDetails(lineDiffDetails)

    @updateSelectedHunk()
    @updateDiffDetailsDisplay()

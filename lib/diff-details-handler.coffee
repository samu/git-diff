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
    # TODO is it possible to listen to only horizontal cursor changes?
    @cursorSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
      @updateCurrentRow()
    @updateCurrentRow()

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updateCurrentRow: ->
    newCurrentRow = @getActiveTextEditor()?.getCursorBufferPosition()?.row + 1
    if newCurrentRow != @currentRow
      @currentRow = newCurrentRow
      @updateSelectedHunk()
      @updateDiffDetailsDisplay()

  toggleShowDiffDetails: ->
    @showDiffDetails = !@showDiffDetails
    @updateDiffDetailsDisplay()

  updateSelectedHunk: ->
    @selectedHunk = null

    if @diffs? and @currentRow?
      for {oldStart, newStart, oldLines, newLines} in @diffs
        unless oldLines is 0 and newLines > 0
          if newLines is 0 and oldLines > 0
            if @currentRow == newStart
              @selectedHunk = {newStart, newEnd: newStart}
              break
          else
            if newStart <= @currentRow
              newEnd = newStart + newLines - 1
              if @currentRow <= newEnd
                @selectedHunk = {newStart, newEnd}
                break

  getHunkDetails: (start, end) ->
    newHunkDetails = []
    for details in @lineDiffDetails
      if details.hunk == "#{start}#{end}" and details.oldLineNo >= 0
        newHunkDetails.push(details.line)
    newHunkDetails

  updateDiffDetailsDisplay: ->
    if @selectedHunk? and @showDiffDetails
      @diffDetailsView.remove() if @diffDetailsView?
      @diffDetailsView = new DiffDetailsView(@editorView)
      @diffDetailsView.setPosition(@selectedHunk.newEnd)
      hunkDetails = @getHunkDetails(@selectedHunk.newStart, @selectedHunk.newEnd)
      @diffDetailsView.setHunkDetails(hunkDetails)
    else
      @diffDetailsView.remove() if @diffDetailsView?
      @diffDetailsView = null

  notifyContentsModified: (diffs, buffer) ->
    @diffs = diffs

    if path = buffer?.getPath()
      @lineDiffDetails = atom.project.getRepo()?.getLineDiffDetails?(path, buffer.getText())
      if @lineDiffDetails?
        for details in @lineDiffDetails
          newEnd = null
          if details.newLines == 0
            newEnd = details.newStart
          else
            newEnd = details.newStart+details.newLines-1

          details.hunk = "#{details.newStart}#{newEnd}"

    @updateSelectedHunk(diffs)
    @updateDiffDetailsDisplay()

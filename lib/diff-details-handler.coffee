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
    @currentRow = @getActiveTextEditor()?.getCursorBufferPosition()?.row + 1
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
              @selectedHunk = {newStart, newStart}
              break
          else
            if newStart <= @currentRow
              newEnd = newStart + newLines - 2
              if @currentRow <= newEnd
                @selectedHunk = {newStart, newEnd}
                break

    console.log @selectedHunk

  updateDiffDetailsDisplay: ->
    if @selectedHunk? and @showDiffDetails
      @diffDetails.remove() if @diffDetails?
      @diffDetails = new DiffDetailsView(@editorView)
      @diffDetails.setPosition(@selectedHunk.newEnd)
    else
      @diffDetails.remove() if @diffDetails?
      @diffDetails = null

  updateDiffDetails: ->

  notifyContentsModified: (diffs) ->
    console.log "CONTENTS MODIFIED"
    console.log "#{diff.newStart} : #{diff.newLines}" for diff in diffs
    @diffs = diffs
    # @diffDetails.remove() if @diffDetails?
    # @diffDetails = null

    @updateSelectedHunk(diffs)
    @updateDiffDetailsDisplay()

DiffDetailsView = require './diff-details-view'
{Subscriber} = require 'emissary'

class DiffDetailsDataManager
  constructor: ->
    console.log "constructor"
    @invalidate()

  liesBetween: (hunk, row) ->
    hunk.start <= row <= hunk.end

  getSelectedHunk: (currentRow) ->
    if !@selectedHunk? or @selectedHunkInvalidated or !@liesBetween(@selectedHunk, currentRow)
      @updateLineDiffDetails()
      @updateSelectedHunk(currentRow)

    @selectedHunkInvalidated = false
    @selectedHunk

  updateSelectedHunk: (currentRow) ->
    @selectedHunk = null

    # lineDiffDetails = @getLineDiffDetails()

    if @lineDiffDetails?
      for hunk in @lineDiffDetails
        if @liesBetween(hunk, currentRow)
          @selectedHunk = hunk
          break

  updateLineDiffDetails: () ->
    if !@lineDiffDetails? or @lineDiffDetailsInvalidated
      @prepareLineDiffDetails(@repo, @path, @text)

    @lineDiffDetailsInvalidated = false
    @lineDiffDetails

  prepareLineDiffDetails: (repo, path, text) ->
    @lineDiffDetails = null

    rawLineDiffDetails = repo.getLineDiffDetails(path, text)

    return unless rawLineDiffDetails?

    @lineDiffDetails = []
    hunk = null

    for {oldStart, newStart, oldLines, newLines, oldLineNo, newLineNo, line} in rawLineDiffDetails
      console.log "processing hunk"
      unless oldLines is 0 and newLines > 0
        # process modifications and deletions only
        if not hunk? or (newStart != hunk.start)
          # create a new hunk entry if the hunk start of the previous line
          # is different to the current

          newEnd = null
          kind = null
          if newLines is 0 and oldLines > 0
            newEnd = newStart
            kind = "d"
          else
            newEnd = newStart + newLines - 1
            kind = "m"

          hunk = {
            start: newStart, end: newEnd,
            oldLines: [], newLines: [],
            newString: "", oldString: ""
            kind
          }
          @lineDiffDetails.push(hunk)

        if newLineNo >= 0
          hunk.newLines.push(line)
          hunk.newString += line
        else
          hunk.oldLines.push(line)
          hunk.oldString += line

  invalidate: (@repo, @path, @text) ->
    @selectedHunkInvalidated = true
    @lineDiffDetailsInvalidated = true

module.exports = class DiffDetailsHandler
  Subscriber.includeInto(this)

  constructor: (@editorView) ->
    {@editor} = @editorView
    @buffer = @editor.getBuffer()

    @showDiffDetails = false
    @lineDiffDetails = null

    @diffDetailsDataManager = new DiffDetailsDataManager()

    @subscribeToCommand @editorView, 'git-diff:toggle-diff-details', =>
      @toggleShowDiffDetails()

    @updateCurrentRow()

    @initializeSubscriptions()

  initializeSubscriptions: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
      @notifyChangeCursorPosition()

  notifyChangeCursorPosition: ->
    @updateCurrentRow()

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
      @updateDiffDetailsDisplay()

  removeSubscriptions: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = null

  toggleShowDiffDetails: ->
    @showDiffDetails = !@showDiffDetails
    @updateDiffDetailsDisplay()

  notifyContentsModified: ->
    repo = atom.project.getRepo()
    path = @buffer?.getPath()
    text = @buffer.getText()
    @diffDetailsDataManager.invalidate(repo, path, text)
    if @showDiffDetails
      @updateDiffDetailsDisplay()

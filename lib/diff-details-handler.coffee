DiffDetailsView = require './diff-details-view'
{Subscriber} = require 'emissary'

module.exports = class DiffDetailsHandler
  Subscriber.includeInto(this)

  constructor: (@editorView) ->
    {@editor} = @editorView
    @buffer = @editor.getBuffer()

    @showDiffDetails = false
    @lineDiffDetails = null

    @subscribeToCommand @editorView, 'git-diff:toggle-diff-details', =>
      @toggleShowDiffDetails()

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  updateDiffDetailsDisplay: ->
    if @showDiffDetails and @selectedHunk?
      @diffDetailsView = new DiffDetailsView(@editorView) unless @diffDetailsView?
      @diffDetailsView.setPosition(@selectedHunk.end)
      @diffDetailsView.setSelectedHunk(@selectedHunk)
    else
      @diffDetailsView.remove() if @diffDetailsView?
      @diffDetailsView = null

  updateCurrentRow: ->
    console.log "update current row"
    if @showDiffDetails
      newCurrentRow = @getActiveTextEditor()?.getCursorBufferPosition()?.row + 1
      if newCurrentRow != @currentRow
        @currentRow = newCurrentRow
        hunkHasChanged = @updateSelectedHunk()
        @updateDiffDetailsDisplay() if hunkHasChanged

  initializeSubscriptions: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = @getActiveTextEditor()?.onDidChangeCursorPosition =>
      @updateCurrentRow()
    @updateCurrentRow()

  removeSubscriptions: ->
    @cursorSubscription?.dispose()
    @cursorSubscription = null

  toggleShowDiffDetails: ->
    @showDiffDetails = !@showDiffDetails

    @prepareLineDiffDetails() unless @lineDiffDetails
    @updateSelectedHunk()
    @updateDiffDetailsDisplay()

    if @showDiffDetails and @lineDiffDetails?
      @initializeSubscriptions()
    else
      @removeSubscriptions()

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

  prepareLineDiffDetails: ->
    if path = @buffer?.getPath()
      if rawLineDiffDetails = atom.project.getRepo()?.getLineDiffDetails(path, @buffer.getText())
        console.log "preparing line diff details"

        return false unless rawLineDiffDetails.length > 0

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
        return true
    return false

  notifyContentsModified: ->
    @lineDiffDetails = null
    @selectedHunk = null
    if @showDiffDetails
      hasDiffs = @prepareLineDiffDetails()
      if hasDiffs
        @updateSelectedHunk()
        @updateDiffDetailsDisplay()
      else
        @updateDiffDetailsDisplay()
        @showDiffDetails = false
        @removeSubscriptions()

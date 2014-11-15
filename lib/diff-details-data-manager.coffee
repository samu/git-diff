module.exports = class DiffDetailsDataManager
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

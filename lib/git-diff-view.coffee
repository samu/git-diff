{Subscriber} = require 'emissary'
DiffDetailsView = require './diff-details-view'

module.exports =
class GitDiffView
  Subscriber.includeInto(this)

  constructor: (@editorView) ->
    {@editor, @gutter} = @editorView
    @decorations = {}
    @markers = null

    @diffDetailsView = new DiffDetailsView(@editorView)

    @subscribe @editorView, 'editor:path-changed', @subscribeToBuffer
    @subscribe atom.project.getRepo(), 'statuses-changed', =>
      @scheduleUpdate()
    @subscribe atom.project.getRepo(), 'status-changed', (path) =>
      @scheduleUpdate() if path is @editor.getPath()

    @subscribeToBuffer()

    @subscribe @editorView, 'editor:will-be-removed', =>
      @cancelUpdate()
      @unsubscribe()
      @unsubscribeFromBuffer()

    @subscribeToCommand @editorView, 'git-diff:move-to-next-diff', =>
      @moveToNextDiff()
    @subscribeToCommand @editorView, 'git-diff:move-to-previous-diff', =>
      @moveToPreviousDiff()

    @subscribe atom.config.observe 'git-diff.showIconsInEditorGutter', =>
      if atom.config.get 'git-diff.showIconsInEditorGutter'
        @gutter.addClass('git-diff-icon')
      else
        @gutter.removeClass('git-diff-icon')

    @subscribe atom.config.observe 'editor.showLineNumbers', =>
      {@gutter} = @editorView
      if atom.config.get('editor.showLineNumbers') and atom.config.get('git-diff.showIconsInEditorGutter')
        @gutter.addClass('git-diff-icon')

  moveToNextDiff: ->
    cursorLineNumber = @editor.getCursorBufferPosition().row + 1
    nextDiffLineNumber = null
    firstDiffLineNumber = null
    for {newStart} in @diffs ? []
      if newStart > cursorLineNumber
        nextDiffLineNumber ?= newStart - 1
        nextDiffLineNumber = Math.min(newStart - 1, nextDiffLineNumber)

      firstDiffLineNumber ?= newStart - 1
      firstDiffLineNumber = Math.min(newStart - 1, firstDiffLineNumber)

    # Wrap around to the first diff in the file
    nextDiffLineNumber = firstDiffLineNumber unless nextDiffLineNumber?

    @moveToLineNumber(nextDiffLineNumber)

  moveToPreviousDiff: ->
    cursorLineNumber = @editor.getCursorBufferPosition().row + 1
    previousDiffLineNumber = -1
    lastDiffLineNumber = -1
    for {newStart} in @diffs ? []
      if newStart < cursorLineNumber
        previousDiffLineNumber = Math.max(newStart - 1, previousDiffLineNumber)
      lastDiffLineNumber = Math.max(newStart - 1, lastDiffLineNumber)

    # Wrap around to the last diff in the file
    previousDiffLineNumber = lastDiffLineNumber if previousDiffLineNumber is -1

    @moveToLineNumber(previousDiffLineNumber)

  moveToLineNumber: (lineNumber=-1) ->
    if lineNumber >= 0
      @editor.setCursorBufferPosition([lineNumber, 0])
      @editor.moveCursorToFirstCharacterOfLine()

  unsubscribeFromBuffer: ->
    if @buffer?
      @removeDecorations()
      @buffer.off 'contents-modified', @notifyContentsModified
      @buffer = null

  subscribeToBuffer: =>
    @unsubscribeFromBuffer()

    if @buffer = @editor.getBuffer()
      @scheduleUpdate()
      @buffer.on 'contents-modified', @notifyContentsModified

  cancelUpdate: ->
    clearImmediate(@immediateId)

  scheduleUpdate: ->
    @cancelUpdate()
    @immediateId = setImmediate(@notifyContentsModified)

  notifyContentsModified: =>
    return if @editor.isDestroyed()
    @updateDiffs()
    @diffDetailsView.notifyContentsModified()

  updateDiffs: =>
    @removeDecorations()
    if path = @buffer?.getPath()
      if @diffs = atom.project.getRepo()?.getLineDiffs(path, @buffer.getText())
        @addDecorations(@diffs)

  addDecorations: (diffs) ->
    for {oldStart, newStart, oldLines, newLines} in diffs
      startRow = newStart - 1
      endRow = newStart + newLines - 2
      if oldLines is 0 and newLines > 0
        @markRange(startRow, endRow, 'git-line-added')
      else if newLines is 0 and oldLines > 0
        @markRange(startRow, startRow, 'git-line-removed')
      else
        @markRange(startRow, endRow, 'git-line-modified')
    return

  removeDecorations: ->
    return unless @markers?
    marker.destroy() for marker in @markers
    @markers = null

  markRange: (startRow, endRow, klass) ->
    marker = @editor.markBufferRange([[startRow, 0], [endRow, Infinity]], invalidate: 'never')
    @editor.decorateMarker(marker, type: 'gutter', class: klass)
    @markers ?= []
    @markers.push(marker)

import asyncdispatch
import httpclient
import options
import strformat
import strutils
import suru


proc downloadFile*(url: string, filename: string) {.async.} =
  proc format(bar: SingleSuruBar): string =
    let downloaded = bar.progress.formatSize
    let totalStr = bar.total.formatSize
    let perSecond = if bar.progress == 0: "0" else: int64(bar.perSecond).formatSize
    &"{(bar.percent*100).int:>3}%|{bar.barDisplay}| " &
      &"{(downloaded).align(totalStr.len, ' ')}" &
      &"/{totalStr} [{bar.elapsed.formatTime}<{bar.eta.formatTime}, " &
      &"{perSecond}/sec]"

  var bars = none(SuruBar)
  var downloaded = 0
  var fileSize: int

  proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
    if bars.isNone:
      bars = some(initSuruBar())
      fileSize = int(total)
      bars.get[0].format = format
      bars.get.setup(fileSize)
    let progress = int(progress)
    let diff = progress - downloaded
    downloaded = progress
    bars.get[0].inc(diff)
    bars.get.update()

  var client = newAsyncHttpClient()
  client.onProgressChanged = onProgressChanged
  await client.downloadFile(url, filename)
  bars.get[0].inc(fileSize - downloaded)
  bars.get.update()
  bars.get.finish()

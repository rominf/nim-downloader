import asyncdispatch
import httpclient
import options
import strformat
import strutils
import suru

proc downloadFile*(url: string, filename: string) {.async.} =
  var bars = none(SuruBar)
  var downloaded = 0

  proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
    if bars.isNone:
      bars = some(initSuruBar())
      bars.get.setup(int(total))
    let progress = int(progress)
    let diff = progress - downloaded
    downloaded = progress
    bars.get[0].inc(diff)
    bars.get.update()

  var client = newAsyncHttpClient()
  client.onProgressChanged = onProgressChanged
  await client.downloadFile(url, filename)

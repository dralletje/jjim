import fs from 'fs'

import * as jjim from './'

let data = []
process.stdin.on('readable', function() {
  const buff = this.read()
  if (buff !== null) {
    data.push(buff)
  } else {
    const code = Buffer.concat(data).toString()
    console.log(JSON.stringify(jjim.graph(code), undefined, 2))
  }
})

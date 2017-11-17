module.exports = (robot) ->
   robot.hear /vsoInfo/i, (res) ->
      res.send "UserName: " + process.env.VSO_USERNAME
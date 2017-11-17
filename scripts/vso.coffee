module.exports = (robot) ->
   robot.hear /vsoItem (.*)/i, (res) ->
      taskItem = res.match[1]
      baseUrl = "https://o365smallbizteam.visualstudio.com"
      url = "#{baseUrl}/DefaultCollection/_apis_wit/workitems?api-version=1.0&ids=#{taskItem}"
      auth = 'Basic' + new Buffer(process.env.VSO_USERNAME + ':' + process.env.VSO_PAT).toString('base64')
      robot.http(url)
	      .header('Authorization', auth)
	      .get() (err, httpRes, body) -> 
		      if err
			      res.send "Encountered an error: #{err}"
		      else
			      res.send "Successful #{body}"
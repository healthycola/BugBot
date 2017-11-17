module.exports = (robot) ->
	robot.hear /vsoItem (.*)/i, (res) ->
	  taskItem = res.match[1]
	  baseUrl = "https://o365smallbizteam.visualstudio.com"
	  url = "#{baseUrl}/DefaultCollection/_apis/wit/workitems?api-version=1.0&ids=#{taskItem}"
	  auth = 'Basic' + new Buffer(process.env.VSO_USERNAME + ':' + process.env.VSO_PAT).toString('base64')
	  console.log("Getting: #{url}")
	  robot.http(url)
	      .header('Authorization', auth)
	      .get() (err, httpRes, body) -> 
		      if err
			      res.send "Encountered an error: #{err}"
		      else
			      res.send "Successful #{body}"

	robot.hear /ios (.*)/i, (res) ->
	  title = res.match[1]
	  baseUrl = "https://o365smallbizteam.visualstudio.com"
	  project = "Invoicing-iOS"
	  workItemType = "Bug"
	  url = "#{baseUrl}/DefaultCollection/#{project}/_apis/wit/workitems/$#{workItemType}?api-version=1.0"
	  auth = 'Basic' + new Buffer(process.env.VSO_USERNAME + ':' + process.env.VSO_PAT).toString('base64')
	  console.log("Posting: #{url}")
	  titleWorkItem =
	  	op: "add"
	  	path: "/fields/System.Title"
	  	value: title

	  workItems = [titleWorkItem]
	  data = JSON.stringify(workItems)
	  robot.http(url)
	      .header('Authorization', auth)
	      .post(data) (err, httpRes, body) -> 
		      if err
			      res.send "Encountered an error: #{err}"
		      else
			      res.send "Successful #{body}"
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
		  .header('Content-Type', 'application/json-patch+json')
	      .header('Authorization', auth)
	      .patch(data) (err, httpRes, body) -> 
		      if err
			      res.send "Encountered an error: #{err}"
		      else
			      res.send "Successful #{body}"

	robot.hear /hi (.*)/i, (res) ->
		getLastWord = (string) ->
			words = string.split(/[\s,]+/)
			return words[words.length - 1]

		getUserName = (word) ->
			return word.match(/([a-zA-Z0-9.,$;]+)$/) if (/^[@]([a-zA-Z0-9.,$;]+)$/.test(word))
			return null

		getUser = (userName) ->
			console.log("Checking for #{userName}")
			for own key, user of robot.brain.data.users
				return user if user.name == userName
			return null

		response = "Hi #{res.envelope.user.name}, #{res.envelope.user.profile.email}!"
		lastWord = getLastWord(res.match[1])
		userName = getUserName(lastWord)
		user = getUser(userName) if userName
		response += "User Id is #{user.id}" if user
		res.send response

	robot.respond /show users$/i, (res) ->
		response = ""

		for own key, user of robot.brain.data.users
		  response += "#{user.id} #{user.name}"
		  response += " <#{user.email_address}>" if user.email_address
		  response += "\n"
		res.send response
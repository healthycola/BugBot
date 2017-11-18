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

	robot.hear /ios: ([@][\S]+){1} (.*)/i, (res) ->
		project = "Invoicing-iOS"
		userName = res.match[1]
		title = res.match[2]
		logBug(title, userName, project)

	logBug = (title, userName, project) ->
		baseUrl = "https://o365smallbizteam.visualstudio.com"
		workItemType = "Bug"
		url = "#{baseUrl}/DefaultCollection/#{project}/_apis/wit/workitems/$#{workItemType}?api-version=1.0"
		auth = 'Basic' + new Buffer(process.env.VSO_USERNAME + ':' + process.env.VSO_PAT).toString('base64')
		console.log("Posting: #{url}")
		workItems = []
		user = getUser(userName)
		if user
			userWorkItem =
				op: "add"
				path: "/fields/System.AssignedTo"
				value: "#{user.email_address}"
			title = title.substring(title.begin, title.lastIndexOf(getLastWord(title)))
			workItems.push(userWorkItem)
		titleWorkItem =
			op: "add"
			path: "/fields/System.Title"
			value: title
		workItems.push(titleWorkItem)

		data = JSON.stringify(workItems)
		robot.http(url)
			.header('Content-Type', 'application/json-patch+json')
			.header('Authorization', auth)
			.patch(data) (err, httpRes, body) ->
				if err
					res.send "Encountered an error: #{err}"
					return
				data = null
				try
					data = JSON.parse body
				catch error
					return
				links = data["_links"]
				if !links
					res.send "Error"
					return
				res.send "Bug logged at #{links["html"]["href"]}"
			      

	robot.hear /hi (.*)/i, (res) ->
		response = "Hi #{res.envelope.user.name}, #{res.envelope.user.profile.email}!"
		user = getUserFromLastWord(res)
		response += "User email is #{user.email_address}" if user
		res.send response

	robot.hear /test: ([@][\S]+){1} (.*)/i, (res) ->
		res.send "User #{res.match[1]}"
		res.send "Title #{res.match[2]}"

	getLastWord = (string) ->
			words = string.split(/[\s,]+/)
			return words[words.length - 1]

	getUser = (userName) ->
			return user for own key, user of robot.brain.data.users when user.name is userName
			return null

	getUserFromLastWord = (res) ->	
		getUserName = (word) ->
			matches = if (/^[@]([a-zA-Z0-9.,$;]+)$/.test(word)) then word.match(/([a-zA-Z0-9.,$;]+)$/) else null
			return if matches then matches[0] else null

		

		lastWord = getLastWord(res.match[1])
		userName = getUserName(lastWord)
		return if userName then getUser(userName) else null

	robot.respond /show users$/i, (res) ->
		response = ""

		for own key, user of robot.brain.data.users
		  response += "#{user.id} #{user.name}"
		  response += " <#{user.email_address}>" if user.email_address
		  response += "\n"
		res.send response
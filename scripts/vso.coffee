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

	robot.hear /ios: ([@][\S]+){1} ([^{]+?)(?={|$)(?:{(.*?)})?/i, (res) ->
		project = "Invoicing-iOS"
		userName = res.match[1].match(/^[@](.*)/)[1]
		title = res.match[2]
		description = if res.match.length > 3 && res.match[3] != undefined then res.match[3] else null
		logBug(title, userName, description, project, res)


	sendMessage = (results, res) ->
		robot.adapter.client.web.chat.postMessage(
			res.message.room, 
			"Bug created",
			"attachments": [results]
			)

	logBug = (title, userName, description, project, res) ->
		## Begin generating workitem object
		workItems = []
		user = getUser(userName)
		if user
			userWorkItem =
				op: "add"
				path: "/fields/System.AssignedTo"
				value: "#{user.email_address}"
			workItems.push(userWorkItem)
		loggedByWorkItem =
			op: "add"
			path: "/fields/System.CreatedBy"
			value: res.envelope.user.profile.email
		workItems.push(loggedByWorkItem)
		if description
			descriptionWorkItem =
				op: "add"
				path: "/fields/Microsoft.VSTS.TCM.ReproSteps"
				value: description
			workItems.push(descriptionWorkItem)
		titleWorkItem =
			op: "add"
			path: "/fields/System.Title"
			value: title
		workItems.push(titleWorkItem)
		postBug(workItems, project, res)

	postBug = (workItems, project, res) ->
		#setup
		baseUrl = "https://o365smallbizteam.visualstudio.com"
		workItemType = "Bug"
		url = "#{baseUrl}/DefaultCollection/#{project}/_apis/wit/workitems/$#{workItemType}?api-version=1.0"
		auth = 'Basic' + new Buffer(process.env.VSO_USERNAME + ':' + process.env.VSO_PAT).toString('base64')
		console.log("Posting: #{url}")

		data = JSON.stringify(workItems)
		robot.http(url)
			.header('Content-Type', 'application/json-patch+json')
			.header('Authorization', auth)
			.patch(data) (err, httpRes, body) ->
				if err
					res.send "Encountered an error: #{err}"
				return unless !err

				data = null
				try
					data = JSON.parse body
				catch error
					res.send "Error! #{error}"
					return
				links = data["_links"]
				if !links
					res.send "Error! #{body}"
				return unless links
				response = createSlackResponse(data)
				sendMessage(response, res)

	
	createSlackResponse = (vsoResponse) ->
		link = vsoResponse["_links"]["html"]["href"]
		title = vsoResponse["fields"]["System.Title"]
		assignedTo = vsoResponse["fields"]["System.AssignedTo"]
		id = vsoResponse["id"]
		res =
			as_user: true,
			fallback: "Bug link #{link}",
			title: "Bug #{id} assigned to #{assignedTo}",
			title_link: link,
			text: title,
			color: "#ba4444"

	# robot.hear /hi (.*)/i, (res) ->
	# 	response = "Hi #{res.envelope.user.name}, #{res.envelope.user.profile.email}!"
	# 	user = getUserFromLastWord(res)
	# 	response += "User email is #{user.email_address}" if user
	# 	res.send response

	robot.hear /test: (.*)/i, (res) ->
		res.send "Testing"
		sendMessage(null, res)

	getUser = (userName) ->
			return user for own key, user of robot.brain.data.users when user.name is userName
			return null

	# robot.respond /show users$/i, (res) ->
	# 	response = ""

	# 	for own key, user of robot.brain.data.users
	# 	  response += "#{user.id} #{user.name}"
	# 	  response += " <#{user.email_address}>" if user.email_address
	# 	  response += "\n"
	# 	res.send response
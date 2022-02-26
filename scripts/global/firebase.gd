extends Node



#TODO: implement firebase handling for user management and stuff
#Alternatively, we might use the python launcher for this instead.

var guid
var token

var client

func fb_init(): #This function creates the httpclient that is required for this script to function
	client = HTTPRequest.new()
	get_node("/root").call_deferred("add_child", client)
	
	pass

#Also will need a debug mode

func fb_login(email, passwd):
	pass

func fb_signup(email, passwd):
	if !client: 
		printerr("ERROR: HTTPRequest node not initialized")
		return
	#TODO: actually do error checking
	var body = {
		"email":email,
		"password":passwd
	}
	
	client.request("https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=", [], true, HTTPClient.METHOD_POST, JSON.print(body))
	
	var result = yield(client, "request_completed") as Array
	print(result)

func fb_anonym_signin():
	if !client:
		printerr("ERROR: HTTPRequest node not initialized")
		return

#Database functions

func fb_dbget(path):
	pass
